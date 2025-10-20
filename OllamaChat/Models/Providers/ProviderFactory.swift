//
//  ProviderFactory.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

enum ProviderFactory {
    @MainActor
    static func createProvider(for configuration: ChatCompletion) throws -> any ChatCompletionAbility {
        switch configuration.provider {
        case .ollama:
            return OllamaProvider(configuration: configuration)
        case .openai, .anthropic, .gemini, .deepseek, .groq, .togetherai, .custom:
            return AIProxyProvider(configuration: configuration)
        }
    }

    static func validateConfiguration(_ configuration: ChatCompletion) throws {
        switch configuration.provider {
        case .ollama:
            // Validate Ollama configuration
            guard !configuration.endpoint.isEmpty else {
                throw ChatCompletionError.invalidConfiguration("Ollama endpoint is required")
            }

            // Check if endpoint is a valid URL
            guard let _ = URL(string: configuration.endpoint) else {
                throw ChatCompletionError.invalidConfiguration("Invalid Ollama endpoint URL")
            }

        case .openai, .anthropic, .gemini, .deepseek, .groq, .togetherai, .custom:
            // Validate API key requirements
            if configuration.provider.requiresAPIKey {
                guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
                    throw ChatCompletionError.invalidConfiguration("API key is required for \(configuration.provider.displayName)")
                }
            }

            // Validate endpoint for custom API
            if configuration.provider == .custom {
                guard !configuration.endpoint.isEmpty else {
                    throw ChatCompletionError.invalidConfiguration("Custom API endpoint is required")
                }

                guard let _ = URL(string: configuration.endpoint) else {
                    throw ChatCompletionError.invalidConfiguration("Invalid custom API endpoint URL")
                }
            }
        }
    }

    static func getDefaultConfiguration(for provider: ModelProvider) -> ChatCompletion {
        switch provider {
        case .ollama:
            return ChatCompletion(
                provider: .ollama,
                name: "Local Ollama",
                endpoint: "http://127.0.0.1:11434",
                apiKey: nil,
                models: ["llama2"],
                configJSONRaw: nil
            )
        case .openai:
            return ChatCompletion(
                provider: .openai,
                name: "OpenAI GPT",
                endpoint: "https://api.openai.com/v1",
                apiKey: nil,
                models: ["gpt-3.5-turbo", "gpt-4"],
                configJSONRaw: """
                {
                    "model": "gpt-3.5-turbo",
                    "useProxy": true
                }
                """
            )
        case .anthropic:
            return ChatCompletion(
                provider: .anthropic,
                name: "Anthropic Claude",
                endpoint: "https://api.anthropic.com",
                apiKey: nil,
                models: ["claude-3-sonnet", "claude-3-opus"],
                configJSONRaw: """
                {
                    "model": "claude-3-sonnet-20240229",
                    "useProxy": true
                }
                """
            )
        case .gemini:
            return ChatCompletion(
                provider: .gemini,
                name: "Google Gemini",
                endpoint: "https://generativelanguage.googleapis.com",
                apiKey: nil,
                models: ["gemini-pro"],
                configJSONRaw: """
                {
                    "model": "gemini-pro",
                    "useProxy": true
                }
                """
            )
        case .deepseek:
            return ChatCompletion(
                provider: .deepseek,
                name: "DeepSeek",
                endpoint: "https://api.deepseek.com",
                apiKey: nil,
                models: ["deepseek-chat", "deepseek-coder"],
                configJSONRaw: """
                {
                    "model": "deepseek-chat",
                    "useProxy": true
                }
                """
            )
        case .groq:
            return ChatCompletion(
                provider: .groq,
                name: "Groq",
                endpoint: "https://api.groq.com/openai/v1",
                apiKey: nil,
                models: ["llama3-8b-8192", "mixtral-8x7b-32768"],
                configJSONRaw: """
                {
                    "model": "llama3-8b-8192",
                    "useProxy": true
                }
                """
            )
        case .togetherai:
            return ChatCompletion(
                provider: .togetherai,
                name: "Together AI",
                endpoint: "https://api.together.xyz/v1",
                apiKey: nil,
                models: ["meta-llama/Llama-3-8b-chat-hf"],
                configJSONRaw: """
                {
                    "model": "meta-llama/Llama-3-8b-chat-hf",
                    "useProxy": true
                }
                """
            )
        case .custom:
            return ChatCompletion(
                provider: .custom,
                name: "Custom API",
                endpoint: "",
                apiKey: nil,
                models: [],
                configJSONRaw: """
                {
                    "model": "your-model-name",
                    "useProxy": false
                }
                """
            )
        }
    }
}