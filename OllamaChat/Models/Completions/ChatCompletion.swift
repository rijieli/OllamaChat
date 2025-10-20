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
    case deepseek
    case groq
    case togetherai
    case custom

    var displayName: String {
        switch self {
        case .ollama: return "Ollama (Local)"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic Claude"
        case .gemini: return "Google Gemini"
        case .deepseek: return "DeepSeek"
        case .groq: return "Groq"
        case .togetherai: return "Together AI"
        case .custom: return "Custom API"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama: return false
        case .openai, .anthropic, .gemini, .deepseek, .groq, .togetherai, .custom: return true
        }
    }

    var supportsProxy: Bool {
        switch self {
        case .ollama: return false
        case .openai, .anthropic, .gemini, .deepseek, .groq, .togetherai, .custom: return true
        }
    }
}

struct ChatCompletion: Codable, Identifiable {
    let id: String
    var provider: ModelProvider
    var name: String
    var endpoint: String
    var apiKey: String?
    var models: [String]
    var configJSONRaw: String?

    init(
        provider: ModelProvider,
        name: String,
        endpoint: String,
        apiKey: String?,
        models: [String] = [],
        configJSONRaw: String? = nil
    ) {
        self.id = UUID().uuidString
        self.provider = provider
        self.name = name
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.configJSONRaw = configJSONRaw
        self.models = models
    }
}
