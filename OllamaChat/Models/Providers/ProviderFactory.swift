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
        case .openai:
            return OpenAIProvider(configuration: configuration)
        case .anthropic:
            return AnthropicProvider(configuration: configuration)
        case .gemini:
            return GeminiProvider(configuration: configuration)
        case .openrouter:
            return OpenRouterDirectProvider(configuration: configuration)
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

        case .openai, .anthropic, .gemini, .openrouter:
            // Validate API key requirements
            if configuration.provider.requiresAPIKey {
                guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
                    throw ChatCompletionError.invalidConfiguration("API key is required for \(configuration.provider.displayName)")
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
                selectedModel: "llama2",
                models: ["llama2"]
            )
        case .openai:
            return ChatCompletion(
                provider: .openai,
                name: "OpenAI GPT",
                endpoint: "https://api.openai.com/v1",
                apiKey: nil,
                selectedModel: "gpt-4o",
                models: [
                    "gpt-4o",
                    "gpt-4o-mini",
                    "gpt-4-turbo",
                    "gpt-4",
                    "gpt-3.5-turbo"
                ]
            )
        case .anthropic:
            return ChatCompletion(
                provider: .anthropic,
                name: "Anthropic Claude",
                endpoint: "https://api.anthropic.com",
                apiKey: nil,
                selectedModel: "claude-3-5-sonnet-20241022",
                models: [
                    "claude-3-5-sonnet-20241022",
                    "claude-3-5-haiku-20241022",
                    "claude-3-opus-20240229",
                    "claude-3-sonnet-20240229",
                    "claude-3-haiku-20240307"
                ]
            )
        case .gemini:
            return ChatCompletion(
                provider: .gemini,
                name: "Google Gemini",
                endpoint: "https://generativelanguage.googleapis.com",
                apiKey: nil,
                selectedModel: "gemini-1.5-pro",
                models: [
                    "gemini-1.5-pro",
                    "gemini-1.5-flash",
                    "gemini-1.0-pro"
                ]
            )
        case .openrouter:
            return ChatCompletion(
                provider: .openrouter,
                name: "OpenRouter",
                endpoint: "https://openrouter.ai/api/v1",
                apiKey: nil,
                selectedModel: "anthropic/claude-3.5-sonnet",
                models: [
                    "anthropic/claude-3.5-sonnet",
                    "anthropic/claude-3.5-haiku",
                    "openai/gpt-4o",
                    "openai/gpt-4o-mini",
                    "google/gemini-pro-1.5",
                    "meta-llama/llama-3.1-70b-instruct",
                    "meta-llama/llama-3.1-8b-instruct"
                ]
            )
        }
    }
}