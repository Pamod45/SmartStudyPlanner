import Foundation
import CoreML
import Models       // swift-transformers
import Generation   // swift-transformers
import Tokenizers   // swift-transformers
import Hub

// MARK: - Thread-safe inference actor

actor SmolLM2Service {
    static let shared = SmolLM2Service()

    // ── State ─────────────────────────────────────────────────────────────
    private var languageModel: LanguageModel?
    private var tokenizer: (any Tokenizer)?
    private(set) var isReady = false

    // ── Model constraints (from metadata.json) ────────────────────────────
    //   sequence_length : 32   →  total context window (input + output)
    //   temperature     : 0.3
    //   top_k           : 12
    //   top_p           : 0.75
    private let seqLen: Int   = 32
    private let temperature: Float = 0.3
    private let topK: Int     = 12
    private let topP: Float   = 0.75

    private init() {}

    // MARK: - Setup

    /// Call once at app launch (or lazily before first use).
    func setup() async throws {
        guard !isReady else { return }

        // 1. Tokenizer
        self.tokenizer = try loadBundledTokenizer()
        print("✅ SmolLM2 tokenizer loaded")

        // 2. CoreML model  →  prefer Neural Engine, fall back to CPU
        let modelName = "smollm2_135m_instruct_only_logits"

        guard let outerURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw LLMError.modelNotFound(modelName)
        }

        let modelURL = outerURL.appendingPathComponent("\(modelName).mlmodelc", isDirectory: true)

        
        let mlConfig = MLModelConfiguration()
        // .cpuAndNeuralEngine works on device; simulator forces .cpuOnly automatically
        mlConfig.computeUnits = .cpuAndNeuralEngine

        let coreMLModel = try await Task.detached(priority: .userInitiated) {
            try MLModel(contentsOf: modelURL, configuration: mlConfig)
        }.value

        self.languageModel = try LanguageModel(model: coreMLModel)
        self.isReady = true
        print("✅ SmolLM2Service ready — seqLen=\(seqLen)")
    }

    // MARK: - Public atomic-task API
    // Each call does ONE tiny job so the 32-token window is never exceeded.
    // NLTextAnalyzer handles chunking/keyword-extraction before these are called.

    /// Produce a short topic title from a comma-separated keyword string.
    /// Prompt ≈ 12 tokens → 12 tokens of generation = 24 total, fits in 32.
    func titleFor(keywords: String) async throws -> String {
        let kw = String(keywords.prefix(40))   // guard against runaway input
        let prompt = compactPrompt("Give a short title for: \(kw)")
        return try await generate(prompt: prompt, maxNew: 12)
    }

    /// One-sentence description for a topic name.
    /// Prompt ≈ 12 tokens → 14 tokens of generation = 26 total.
    func describeOneSentence(topic: String) async throws -> String {
        let t = String(topic.prefix(30))
        let prompt = compactPrompt("Briefly explain: \(t)")
        return try await generate(prompt: prompt, maxNew: 14)
    }

    /// A short quiz question for a keyword.
    /// Prompt ≈ 10 tokens → 14 tokens of generation = 24 total.
    func quizQuestion(for keyword: String) async throws -> String {
        let kw = String(keyword.prefix(25))
        let prompt = compactPrompt("Quiz question about \(kw)?")
        return try await generate(prompt: prompt, maxNew: 14)
    }

    /// A concise answer for a quiz question.
    func quizAnswer(for question: String) async throws -> String {
        let q = String(question.prefix(25))
        let prompt = compactPrompt("Answer briefly: \(q)")
        return try await generate(prompt: prompt, maxNew: 12)
    }

    // MARK: - Core generation (sliding-window)

    private func generate(prompt: String, maxNew: Int) async throws -> String {
        guard let model = languageModel, let tokenizer = tokenizer else {
            throw LLMError.notInitialized
        }

        let allTokens = tokenizer.encode(text: prompt)

        // Sliding window: keep the last (seqLen - maxNew) prompt tokens so we
        // always have at least `maxNew` slots free for generation.
        let maxContext = max(1, seqLen - maxNew)
        let contextTokens = allTokens.count > maxContext
            ? Array(allTokens.suffix(maxContext))
            : allTokens
        
        print("🟡 [SmolLM2] PROMPT:\n\(tokenizer.decode(tokens: contextTokens))")
           print("🟡 [SmolLM2] token count: \(contextTokens.count)/\(seqLen)")

        let genConfig = GenerationConfig(
            maxNewTokens: maxNew,
            doSample: true,
            temperature: Float(Double(temperature)),
            topK: topK,
            topP: Float(Double(topP))
        )

        // Off main thread so UI stays responsive
        let output = try await Task.detached(priority: .userInitiated) {
            try await model.generate(config: genConfig, tokens: contextTokens)
        }.value

        let newTokens = Array(output.dropFirst(contextTokens.count))
        let rawDecoded = tokenizer.decode(tokens: newTokens)
        print("🔴 [SmolLM2] RAW OUTPUT: '\(rawDecoded)'")
        
        let cleaned = clean(rawDecoded)
        
        print("🟢 [SmolLM2] CLEANED: '\(cleaned)'")
        return cleaned
    }

    // MARK: - Prompt builder — compact ChatML, no system turn (saves ~8 tokens)

    private func compactPrompt(_ userContent: String) -> String {
        "<|im_start|>user\n\(userContent)<|im_end|>\n<|im_start|>assistant\n"
    }

    // MARK: - Output sanitiser

    private func clean(_ raw: String) -> String {
        var s = raw
        for tok in ["<|im_end|>", "<|im_start|>", "<|endoftext|>",
                    "assistant", "user", "system"] {
            s = s.replacingOccurrences(of: tok, with: "")
        }
        // Collapse runs of whitespace / newlines
        s = s.components(separatedBy: .newlines).joined(separator: " ")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Tokenizer loader (reads from Resources/tokenizer/)

    private func loadBundledTokenizer() throws -> any Tokenizer {
        
        guard let configURL = Bundle.main.url(forResource: "tokenizer_config",
                                              withExtension: "json") else {
            throw LLMError.missingFile("tokenizer_config.json")
        }
        
        guard let dataURL = Bundle.main.url(forResource: "tokenizer",
                                              withExtension: "json") else {
            throw LLMError.missingFile("tokenizer.json")
        }

        let configJSON = try JSONSerialization.jsonObject(
            with: Data(contentsOf: configURL)) as! [NSString: Any]
        let dataJSON = try JSONSerialization.jsonObject(
            with: Data(contentsOf: dataURL))   as! [NSString: Any]
        
        return try AutoTokenizer.from(
            tokenizerConfig: Config(configJSON),
            tokenizerData:   Config(dataJSON)
        )
    }

    // MARK: - Errors

    enum LLMError: LocalizedError {
        case modelNotFound(String)
        case tokenizerNotFound
        case missingFile(String)
        case notInitialized

        var errorDescription: String? {
            switch self {
            case .modelNotFound(let n):  return "CoreML model '\(n).mlmodelc' not found in bundle."
            case .tokenizerNotFound:     return "Resources/tokenizer/ folder not found in bundle."
            case .missingFile(let f):    return "Required tokenizer file '\(f)' is missing."
            case .notInitialized:        return "SmolLM2Service.setup() has not been called yet."
            }
        }
    }
}
