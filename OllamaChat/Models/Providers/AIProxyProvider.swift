//
//  AIProxyProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation
import AIProxy

@MainActor
class AIProxyProvider: ObservableObject, ChatCompletionAbility {
    private let configuration: ChatCompletion
    private var currentTask: Task<Void, Never>?

    init(configuration: ChatCompletion) {
        self.configuration = configuration
    }

    func send(messages: [ChatMessage]) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await processMessages(messages, continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            currentTask = task

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func cancel() async {
        currentTask?.cancel()
        currentTask = nil
    }

    private func processMessages(
        _ messages: [ChatMessage],
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
            throw ChatCompletionError.invalidConfiguration("API key is required for \(configuration.provider.displayName)")
        }

        // Parse configuration JSON if provided
        var model = "gpt-3.5-turbo" // default model
        var useProxy = true
        var partialKey: String?
        var serviceURL: String?

        if let configJSON = configuration.configJSONRaw,
           let configData = configJSON.data(using: .utf8),
           let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any] {
            model = config["model"] as? String ?? model
            useProxy = config["useProxy"] as? Bool ?? true
            partialKey = config["partialKey"] as? String
            serviceURL = config["serviceURL"] as? String
        }

        // Convert messages to OpenAI format
        let openAIMessages = messages.map { message in
            [
                "role": message.role == .user ? "user" : "assistant",
                "content": message.content
            ]
        }

        do {
            // Create the appropriate service based on provider
            switch configuration.provider {
            case .openai:
                try await processOpenAI(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .anthropic:
                try await processAnthropic(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .gemini:
                try await processGemini(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .deepseek:
                try await processDeepSeek(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .groq:
                try await processGroq(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .togetherai:
                try await processTogetherAI(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .custom:
                try await processCustomAPI(
                    messages: openAIMessages,
                    model: model,
                    apiKey: apiKey,
                    useProxy: useProxy,
                    partialKey: partialKey,
                    serviceURL: serviceURL,
                    continuation: continuation
                )
            case .ollama:
                throw ChatCompletionError.invalidConfiguration("Ollama should use OllamaProvider")
            }
        } catch {
            throw ChatCompletionError.unknownError(error)
        }
    }

    private func processOpenAI(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        let service: OpenAIService

        if useProxy, let pKey = partialKey, let sURL = serviceURL {
            service = AIProxy.openAIService(
                partialKey: pKey,
                serviceURL: sURL
            )
        } else {
            service = AIProxy.openAIDirectService(
                unprotectedAPIKey: apiKey,
                baseURL: configuration.endpoint.isEmpty ? nil : configuration.endpoint
            )
        }

        let requestBody = OpenAIChatCompletionRequestBody(
            model: model,
            messages: messages.map { message in
                OpenAIChatCompletionRequestBody.Message.user(
                    content: .text(message["content"] as? String ?? "")
                )
            }
        )

        let stream = try await service.streamingChatCompletionRequest(
            body: requestBody,
            secondsToWait: 60
        )

        for try await chunk in stream {
            if let content = chunk.choices.first?.delta.content {
                continuation.yield(content)
            }
        }

        continuation.finish()
    }

    private func processAnthropic(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for Anthropic Claude
        // Similar structure to OpenAI but using AnthropicService
        continuation.finish()
    }

    private func processGemini(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for Google Gemini
        continuation.finish()
    }

    private func processDeepSeek(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for DeepSeek
        continuation.finish()
    }

    private func processGroq(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for Groq
        continuation.finish()
    }

    private func processTogetherAI(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for Together AI
        continuation.finish()
    }

    private func processCustomAPI(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        useProxy: Bool,
        partialKey: String?,
        serviceURL: String?,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Implementation for custom API endpoints using OpenAI-compatible format
        guard let baseURL = configuration.endpoint.isEmpty ? nil : configuration.endpoint else {
            throw ChatCompletionError.invalidConfiguration("Custom API requires endpoint URL")
        }

        let service = AIProxy.openAIDirectService(
            unprotectedAPIKey: apiKey,
            baseURL: baseURL
        )

        let requestBody = OpenAIChatCompletionRequestBody(
            model: model,
            messages: messages.map { message in
                OpenAIChatCompletionRequestBody.Message.user(
                    content: .text(message["content"] as? String ?? "")
                )
            }
        )

        let stream = try await service.streamingChatCompletionRequest(
            body: requestBody,
            secondsToWait: 60
        )

        for try await chunk in stream {
            if let content = chunk.choices.first?.delta.content {
                continuation.yield(content)
            }
        }

        continuation.finish()
    }
}