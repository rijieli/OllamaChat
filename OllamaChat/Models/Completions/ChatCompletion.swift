//
//  ChatCompletion.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

protocol ChatCompletionAbility {
    func send(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error>
    func cancel() async
}

enum ChatCompletionError: Error, LocalizedError {
    case invalidConfiguration(String)
    case networkError(Error)
    case authenticationError
    case rateLimitError
    case modelNotAvailable(String)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Configuration error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed. Please check your API key."
        case .rateLimitError:
            return "Rate limit exceeded. Please try again later."
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available."
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

enum ModelProvider: String, Codable, CaseIterable {
    case ollama
    case openai
    case anthropic
    case gemini
    case openrouter

    var displayName: String {
        switch self {
        case .ollama: return "Ollama (Local)"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic Claude"
        case .gemini: return "Google Gemini"
        case .openrouter: return "OpenRouter"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama: return false
        case .openai, .anthropic, .gemini, .openrouter: return true
        }
    }

    var supportsProxy: Bool {
        switch self {
        case .ollama: return false
        case .openai, .anthropic, .gemini, .openrouter: return true
        }
    }

    var isOpenAICompatible: Bool {
        switch self {
        case .ollama: return false
        case .openai, .openrouter: return true
        case .anthropic: return false
        case .gemini: return false
        }
    }
}

struct ChatCompletion: Codable, Identifiable {
    let id: String
    var provider: ModelProvider
    var name: String
    var endpoint: String
    var apiKey: String?
    var selectedModel: String
    var models: [String]

    init(
        provider: ModelProvider,
        name: String,
        endpoint: String,
        apiKey: String?,
        selectedModel: String,
        models: [String] = []
    ) {
        self.id = UUID().uuidString
        self.provider = provider
        self.name = name
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.selectedModel = selectedModel
        self.models = models
    }
}
