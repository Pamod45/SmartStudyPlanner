import Foundation
import NaturalLanguage

struct NLTextAnalyzer {

    static func extractKeywords(from text: String,
                                 max: Int = 30) -> [String] {
        var seen    = Set<String>()
        var results = [String]()

        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        let opts: NLTagger.Options = [.omitPunctuation, .omitWhitespace,
                                      .omitOther, .joinNames]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: opts) { tag, range in
            guard let tag, [.personalName, .placeName,
                             .organizationName].contains(tag) else { return true }
            let word = String(text[range])
            if !seen.contains(word) { seen.insert(word); results.append(word) }
            return true
        }

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass,
                             options: opts) { tag, range in
            guard let tag, [.noun, .verb].contains(tag) else { return true }
            let word = String(text[range])
            guard word.count > 3, !seen.contains(word.lowercased()) else { return true }
            seen.insert(word.lowercased())
            results.append(word)
            return true
        }

        return Array(results.prefix(max))
    }

    static func sentences(from text: String) -> [String] {
        var result = [String]()
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !s.isEmpty { result.append(s) }
            return true
        }
        return result
    }

    static func chunks(from text: String,
                       targetCount: Int) -> [String] {
        let sents = sentences(from: text)
        guard sents.count >= targetCount else {
            return sents.isEmpty ? [text] : sents
        }
        let chunkSize = max(1, Int(ceil(Double(sents.count) / Double(targetCount))))
        return stride(from: 0, to: sents.count, by: chunkSize).map { i in
            sents[i..<min(i + chunkSize, sents.count)].joined(separator: " ")
        }
    }

    static func clusterKeywords(_ keywords: [String],
                                 into bucketCount: Int) -> [[String]] {
        guard !keywords.isEmpty, bucketCount > 0 else { return [] }
        guard keywords.count >= bucketCount else {
            return (0..<bucketCount).map { i in
                [keywords[min(i, keywords.count - 1)]]
            }
        }
        let size = Int(ceil(Double(keywords.count) / Double(bucketCount)))
        return stride(from: 0, to: keywords.count, by: size).map { i in
            Array(keywords[i..<min(i + size, keywords.count)])
        }
    }

    static func importantSentences(from text: String,
                                    count: Int = 3) -> [String] {
        let keywords = Set(extractKeywords(from: text, max: 40).map { $0.lowercased() })
        let sents    = sentences(from: text)

        let scored: [(String, Int)] = sents.map { s in
            let words = s.lowercased().components(separatedBy: .whitespaces)
            let score = words.filter { keywords.contains($0) }.count
            return (s, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { $0.0 }
    }

    static func dominantLanguage(of text: String) -> NLLanguage {
        let r = NLLanguageRecognizer()
        r.processString(text)
        return r.dominantLanguage ?? .english
    }
}
