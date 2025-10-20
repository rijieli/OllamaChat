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

        // Convert messages to OpenAI format
        let openAIMessages = messages.map { message in
            [
                "role": message.role == .user ? "user" : "assistant",
                "content": message.content
            ]
        }

        do {
            // Use OpenAI-compatible structure for all supported providers
            if configuration.provider.isOpenAICompatible {
                try await processOpenAICompatible(
                    messages: openAIMessages,
                    model: configuration.selectedModel,
                    apiKey: apiKey,
                    continuation: continuation
                )
            } else {
                // TODO: Implement Anthropic and Gemini specific handling
                throw ChatCompletionError.unknownError(NSError(domain: "NotImplemented", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(configuration.provider.displayName) not yet implemented"]))
            }
        } catch {
            throw ChatCompletionError.unknownError(error)
        }
    }

    private func processOpenAICompatible(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        // Use OpenAI service for all OpenAI-compatible providers
        let service: OpenAIService

        // Configure service based on provider
        switch configuration.provider {
        case .openai:
            service = AIProxy.openAIDirectService(
                unprotectedAPIKey: apiKey,
                baseURL: configuration.endpoint.isEmpty ? nil : configuration.endpoint
            )
        case .openrouter:
            // OpenRouter uses OpenAI-compatible format but with different base URL
            service = AIProxy.openAIDirectService(
                unprotectedAPIKey: apiKey,
                baseURL: configuration.endpoint.isEmpty ? "https://openrouter.ai/api/v1" : configuration.endpoint
            )
        default:
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
}