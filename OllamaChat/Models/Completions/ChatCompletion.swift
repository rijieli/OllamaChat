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
        case .ollama, .openrouter: return false
        case .openai, .anthropic, .gemini: return true
        }
    }

    var isOpenAICompatible: Bool {
        switch self {
        case .ollama: return false
        case .openai: return true
        case .openrouter: return false
        case .anthropic: return false
        case .gemini: return false
        }
    }
}

struct ModelMetadata: Codable {
    var fileSize: String?
    var family: String?
    var format: String?
    var quantizationLevel: String?
    var source: String? // "ollama", "huggingface", etc.
    var parameters: String?
}

struct ChatCompletion: Codable, Identifiable {
    let id: String
    var provider: ModelProvider
    var name: String
    var endpoint: String
    var apiKey: String?
    var selectedModel: String
    var models: [String]

    // New properties for unified handling
    var isEnabled: Bool = true
    var isDefault: Bool = false
    var contextLength: Int?
    var lastUsed: Date?
    var metadata: ModelMetadata?

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

    // Computed properties
    var isValid: Bool {
        switch provider {
        case .ollama:
            return !endpoint.isEmpty && isValidURL(endpoint)
        case .openai, .anthropic, .gemini, .openrouter:
            return !(apiKey?.isEmpty ?? true)
        }
    }

    var displayName: String {
        return name.isEmpty ? provider.displayName : name
    }

    // Helper for URL validation
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }

    // Default configuration for testing
    static let `default` = ChatCompletion(
        provider: .ollama,
        name: "Default Ollama",
        endpoint: "http://localhost:11434",
        apiKey: nil,
        selectedModel: "llama2",
        models: []
    )
}
