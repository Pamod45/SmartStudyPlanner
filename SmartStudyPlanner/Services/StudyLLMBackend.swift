//
//  StudyLLMBackend.swift
//  SmartStudyPlanner
//
//  Created by Pubudu Perera on 2026-05-06.
//

import Foundation
import FoundationModels

struct GeneratedStudyPath {
    struct Topic {
        let order: Int
        let title: String
        let description: String
        let subtopics: [String]
        let weightPercent: Int
    }
    let topics: [Topic]
}

struct GeneratedQuiz {
    struct Item {
        let question: String
        let answer: String
        let keyword: String
    }
    let items: [Item]
}

public struct QuizMCQItem {
    public let questionText: String
    public let options: [String]
    public let correctOptionIndex: Int
    public let category: String
    public let expertTip: String
    public let keyword: String
    
    public init(questionText: String, options: [String], correctOptionIndex: Int, category: String, expertTip: String, keyword: String) {
        self.questionText = questionText
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.category = category
        self.expertTip = expertTip
        self.keyword = keyword
    }
}

public struct QuizGenerationResult {
    public let questions: [QuizMCQItem]
    
    public init(questions: [QuizMCQItem]) {
        self.questions = questions
    }
}

protocol StudyLLMBackend {
    func generateStudyPath(from text: String, topicCount: Int) async throws -> GeneratedStudyPath
    func generateQuiz(from text: String, questionCount: Int) async throws -> GeneratedQuiz
    func generateQuizQuestions(from text: String, questionCount: Int, category: String) async throws -> QuizGenerationResult
}

enum LLMBackendSelector {
    static func resolve(hostedURL: URL) -> StudyLLMBackend {
//        if #available(iOS 26.0, *) {
//            let availability = SystemLanguageModel.default.availability
//            if case .available = availability {
//                print("[LLM] Using FoundationModels (Apple Intelligence)")
//                return FoundationModelsBackend()
//            }
//            print("[LLM] FoundationModels unavailable (\(availability)) — falling back to hosted LLM")
//        }
        print("[LLM] Using HostedLLMBackend → \(hostedURL)")
        return HostedLLMBackend(serverURL: hostedURL)
    }
}
