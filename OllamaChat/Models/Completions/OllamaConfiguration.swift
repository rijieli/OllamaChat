//
//  OllamaConfiguration.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

struct ChatStreamChunk: Equatable {
    var content: String = ""
    var thinking: String = ""

    var isEmpty: Bool {
        content.isEmpty && thinking.isEmpty
    }
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
            return "Authentication failed."
        case .rateLimitError:
            return "Rate limit exceeded. Please try again later."
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available."
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

struct OllamaConfiguration: Codable {
    var endpoint: String
    var selectedModel: String

    init(
        endpoint: String,
        selectedModel: String
    ) {
        self.endpoint = endpoint
        self.selectedModel = selectedModel
    }

    var isValid: Bool {
        guard let url = URL(string: endpoint) else { return false }
        return url.scheme != nil && url.host != nil
    }

    static let `default` = OllamaConfiguration(
        endpoint: "http://127.0.0.1:11434",
        selectedModel: ""
    )
}
