import Foundation
import CoreML
import Models
import Generation
import Tokenizers
import Hub

class LLMService {
    static let shared = LLMService()

    private var languageModel: LanguageModel?
    private var tokenizer: Tokenizer?
    private var isInitialized = false
    private var isInitializing = false

    private init() {}

    private func ensureModelInitialized() async throws {
        guard !isInitialized else { return }

        while isInitializing {
            try await Task.sleep(nanoseconds: 500_000_000)
            if isInitialized { return }
        }

        isInitializing = true
        defer { isInitializing = false }

        // ── 1. Model URL ────────────────────────────────────────────────────
        // Xcode compiles TinyLlama-swift.mlpackage → TinyLlama-swift.mlmodelc
        // at build time. The .mlmodelc sits flat in the bundle (no nested folder
        // like the SmolLM2 bundle had), so we point directly to it.
        let modelName = "TinyLlama-swift"
        guard let modelURL = Bundle.main.url(forResource: modelName,
                                              withExtension: "mlmodelc") else {
            throw LLMError.modelNotFound(modelName)
        }
        print("✅ Model found: \(modelURL.lastPathComponent)")

        // ── 2. Tokenizer ────────────────────────────────────────────────────
        // tokenizer.json and tokenizer_config.json must be added to the Xcode
        // project at the bundle root (NOT inside any subfolder).
        // Download from: huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0
        let bundleRoot = Bundle.main.resourceURL!

        let configURL = bundleRoot.appendingPathComponent("tiny_tokenizer_config.json")
        let dataURL   = bundleRoot.appendingPathComponent("tiny_tokenizer.json")

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw LLMError.tokenizerFileNotFound("tiny_tokenizer_config.json")
        }
        guard FileManager.default.fileExists(atPath: dataURL.path) else {
            throw LLMError.tokenizerFileNotFound("tiny_tokenizer.json")
        }

        let configDict = try JSONSerialization.jsonObject(
            with: Data(contentsOf: configURL)
        ) as! [NSString: Any]

        let dataDict = try JSONSerialization.jsonObject(
            with: Data(contentsOf: dataURL)
        ) as! [NSString: Any]

        self.tokenizer = try AutoTokenizer.from(
            tokenizerConfig: Config(configDict),
            tokenizerData:   Config(dataDict)
        )
        print("✅ Tokenizer loaded")

        // ── 3. CoreML model ─────────────────────────────────────────────────
        // Use cpuAndNeuralEngine on device; simulator automatically falls back
        // to CPU so this is safe for both targets.
        self.languageModel = try await Task.detached(priority: .userInitiated) {
            let mlConfig = MLModelConfiguration()
            mlConfig.computeUnits = .cpuAndNeuralEngine
            let coreMLModel = try MLModel(contentsOf: modelURL, configuration: mlConfig)
            return try LanguageModel(model: coreMLModel)
        }.value

        self.isInitialized = true
        print("✅ LLMService ready — context: \(languageModel!.maxContextLength) tokens")
    }

    // MARK: - Study Path Generation

    func generateStudyPathTopics(from text: String) async throws -> [StudyPathTopic] {
        try await ensureModelInitialized()

        guard let model = languageModel, let tokenizer = tokenizer else {
            throw LLMError.notInitialized
        }

        let prompt       = buildPrompt(for: text)
        let inputTokens  = tokenizer.encode(text: prompt)
        print("LLMService: prompt tokens = \(inputTokens.count)")

        // TinyLlama context is 2048 tokens. Guard against oversized prompts.
        guard inputTokens.count < model.maxContextLength - 80 else {
            throw LLMError.promptTooLong(inputTokens.count, model.maxContextLength)
        }

//        let output = try await Task.detached(priority: .userInitiated) {
//            var config = GenerationConfig(maxNewTokens: 512)
//            config.doSample    = false   // greedy — more reliable for JSON
//            config.temperature = 0.7
//            config.topK        = 50
//            config.topP        = 0.9
//            config.eosTokenId  = tokenizer.convertTokenToId("<|im_end|>") ?? 2
//            return try await model.generate(config: config, tokens: inputTokens)
//        }.value
        
//        let output = try await Task.detached(priority: .userInitiated) {
//            var config = GenerationConfig(maxNewTokens: 80)
//            config.doSample = false
//            await model.resetState()
//            return try await model.generate(config: config, tokens: inputTokens)
//        }.value

//        let newTokens = Array(output.dropFirst(inputTokens.count))

//        let jsonString = tokenizer.decode(tokens: newTokens)
        let jsonString = try await generateManual(
            model: model,
            tokenizer: tokenizer,
            inputTokens: inputTokens
        )

        print("LLMService: raw output — \(jsonString.prefix(300))")

        return try parseTopicsFromJSON(jsonString)
    }

    // MARK: - Quick Smoke Test
    
    private func generateManual(
        model: LanguageModel,
        tokenizer: Tokenizer,
        inputTokens: [Int],
        maxNewTokens: Int = 80
    ) async throws -> String {

        var window    = inputTokens
        var generated = [Int]()
        let eosId     = tokenizer.convertTokenToId("<|im_end|>") ?? 2
        let seqLen    = model.maxContextLength  // 512

        for _ in 0..<maxNewTokens {

            // Pad window to fixed seqLen
            let padLen     = seqLen - window.count
            let paddedIDs  = window + [Int](repeating: 0, count: max(0, padLen))
            let actualLen  = min(window.count, seqLen)

            // Build input as MLMultiArray (avoids MLTensor float32/float16 issues)
            let inputArray = try MLMultiArray(
                shape: [1, NSNumber(value: seqLen)],
                dataType: .int32
            )
            for (i, id) in paddedIDs.prefix(seqLen).enumerated() {
                inputArray[[0, i] as [NSNumber]] = NSNumber(value: id)
            }

            let features = try MLDictionaryFeatureProvider(
                dictionary: ["input_ids": MLFeatureValue(multiArray: inputArray)]
            )

            // Run inference
            let result     = try await model.model.prediction(from: features)
            let outputKey  = result.featureNames.first!
            let logits     = result.featureValue(for: outputKey)!.multiArrayValue!

            // Greedy argmax at last real token position
            let vocabSize  = logits.shape[2].intValue
            let offset     = (actualLen - 1) * vocabSize
            var bestID     = 0
            var bestVal    = Float(-Float.greatestFiniteMagnitude)

            for v in 0..<vocabSize {
                let val = logits[[0, (actualLen - 1) as NSNumber, v as NSNumber]].floatValue
                if val > bestVal { bestVal = val; bestID = v }
            }

            print("DEBUG: next token = \(bestID) (\(tokenizer.decode(tokens: [bestID])))")

            if bestID == eosId { break }

            generated.append(bestID)
            window.append(bestID)

            // Slide window if over seqLen
            if window.count > seqLen { window.removeFirst() }
        }

        return tokenizer.decode(tokens: generated)
    }

    func testGeneration() async throws {
        try await ensureModelInitialized()
        guard let model = languageModel, let tokenizer = tokenizer else { return }

        let prompt = """
        <|im_start|>system
        You are a helpful assistant.<|im_end|>
        <|im_start|>user
        Say hello in one sentence.<|im_end|>
        <|im_start|>assistant

        """

        let inputTokens = tokenizer.encode(text: prompt)
        print("Test prompt tokens: \(inputTokens.count)")

        var config        = GenerationConfig(maxNewTokens: 80)
        config.doSample   = false
        config.eosTokenId = tokenizer.convertTokenToId("<|im_end|>") ?? 2

        let output    = try await model.generate(config: config, tokens: inputTokens)
        let newTokens = Array(output.dropFirst(inputTokens.count))
        print("Test output: \(tokenizer.decode(tokens: newTokens))")
    }

    // MARK: - Prompt

    private func buildPrompt(for text: String) -> String {
        let maxChars = 1000  // ~250 tokens — keeps total prompt under 450 with headroom for output
        let truncated = String(text.prefix(maxChars))

        return """
        <|im_start|>system
        Output ONLY a JSON array. Schema:
        [{"order":1,"title":"T","description":"D","subtopics":["S"],"weightPercent":20}]
        Weights sum to 100.<|im_end|>
        <|im_start|>user
        \(truncated)<|im_end|>
        <|im_start|>assistant

        """
    }

    // MARK: - JSON Parsing

    private func parseTopicsFromJSON(_ raw: String) throws -> [StudyPathTopic] {
        var clean = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip special tokens the model may have emitted
        for token in ["<|im_start|>", "<|im_end|>", "<|endoftext|>",
                      "assistant", "system", "user"] {
            clean = clean.replacingOccurrences(of: token, with: "")
        }

        // Strip markdown code fences if present
        if clean.hasPrefix("```json") { clean = String(clean.dropFirst(7)) }
        else if clean.hasPrefix("```") { clean = String(clean.dropFirst(3)) }
        if clean.hasSuffix("```")      { clean = String(clean.dropLast(3)) }

        // Extract first [...] block
        guard let start = clean.firstIndex(of: "["),
              let end   = clean.lastIndex(of: "]") else {
            throw LLMError.noJSONFound(clean)
        }
        clean = String(clean[start...end]).trimmingCharacters(in: .whitespacesAndNewlines)
        print("LLMService: cleaned JSON — \(clean.prefix(300))")

        struct GeneratedTopic: Codable {
            let order: Int
            let title: String
            let description: String
            let subtopics: [String]
            let weightPercent: Int
        }

        guard let data = clean.data(using: .utf8) else {
            throw LLMError.encodingFailed
        }

        let topics = try JSONDecoder().decode([GeneratedTopic].self, from: data)
        return topics.map { t in
            StudyPathTopic(
                id:                UUID().uuidString,
                order:             t.order,
                title:             t.title,
                description:       t.description,
                subtopics:         t.subtopics,
                weightPercent:     t.weightPercent,
                resourceIds:       [],
                completionPercent: 0,
                isCompleted:       false
            )
        }
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelNotFound(String)
    case tokenizerFileNotFound(String)
    case notInitialized
    case promptTooLong(Int, Int)
    case noJSONFound(String)
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "Model '\(name).mlmodelc' not found in bundle."
        case .tokenizerFileNotFound(let name):
            return "'\(name)' not found in bundle root. Add it from huggingface.co/TinyLlama/TinyLlama-1.1B-Chat-v1.0"
        case .notInitialized:
            return "LLMService not initialized."
        case .promptTooLong(let count, let max):
            return "Prompt too long (\(count) tokens). Model max is \(max)."
        case .noJSONFound(let raw):
            return "No JSON array found in model output: \(raw.prefix(100))"
        case .encodingFailed:
            return "Failed to encode JSON string as UTF-8."
        }
    }
}
