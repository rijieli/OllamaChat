//
//  OpenRouterDirectProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class OpenRouterDirectProvider: ObservableObject, ChatCompletionAbility {
    private let configuration: ChatCompletion
    private var currentTask: Task<Void, Never>?

    init(configuration: ChatCompletion) {
        self.configuration = configuration
    }

    func send(messages: [ChatMessage]) async throws -> AsyncThrowingStream<ChatStreamChunk, Error> {
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
        continuation: AsyncThrowingStream<ChatStreamChunk, Error>.Continuation
    ) async throws {
        guard let apiKey = configuration.apiKey, !apiKey.isEmpty else {
            throw ChatCompletionError.invalidConfiguration("API key is required for OpenRouter")
        }

        // Prepare the request URL
        let baseURL = configuration.endpoint.isEmpty ? "https://openrouter.ai/api/v1" : configuration.endpoint
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw ChatCompletionError.invalidConfiguration("Invalid OpenRouter endpoint URL")
        }

        // Prepare request body
        let requestBody: [String: Any] = [
            "model": configuration.selectedModel,
            "messages": messages.map { message in
                [
                    "role": message.role == .user ? "user" : "assistant",
                    "content": message.content
                ]
            },
            "stream": true,
            "reasoning": [
                "enabled": false
            ]
        ]

        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Add optional HTTP-Referer and X-Title headers
        request.setValue("https://ollamachat.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("OllamaChat", forHTTPHeaderField: "X-Title")

        // Encode request body
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData

        // Create URLSession with custom configuration
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 300
        let session = URLSession(configuration: sessionConfig)

        // Perform the request
        let (bytes, response) = try await session.bytes(for: request)

        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.unknownError(NSError(domain: "OpenRouter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard httpResponse.statusCode == 200 else {
            // Try to read error details
            if let errorData = try? await bytesData(bytes, upTo: 1024),
               let errorString = String(data: errorData, encoding: .utf8) {
                throw ChatCompletionError.unknownError(NSError(domain: "OpenRouter", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenRouter API error: \(errorString)"]))
            } else {
                throw ChatCompletionError.unknownError(NSError(domain: "OpenRouter", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
            }
        }

        // Process streaming response
        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }

            // Parse SSE format (data: {...})
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))

                // Skip "[DONE]" message
                if jsonString == "[DONE]" {
                    continuation.finish()
                    return
                }

                // Parse JSON chunk
                guard let jsonData = jsonString.data(using: .utf8) else { continue }

                do {
                    let chunk = try JSONDecoder().decode(OpenRouterChunk.self, from: jsonData)
                    if let content = chunk.choices.first?.delta.content {
                        continuation.yield(ChatStreamChunk(content: content))
                    }
                } catch {
                    log.error("Failed to decode OpenRouter chunk: \(error)")
                }
            }
        }

        continuation.finish()
    }
}

// MARK: - Data Models

private struct OpenRouterChunk: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let usage: Usage?

    struct Choice: Codable {
        let index: Int?
        let delta: Delta
        let finishReason: String?

        struct Delta: Codable {
            let role: String?
            let content: String?
        }
    }

    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?
    }
}

// Helper to get data from AsyncBytes
private func bytesData(_ bytes: URLSession.AsyncBytes, upTo limit: Int) async throws -> Data {
    var data = Data()
    var iterator = bytes.makeAsyncIterator()

    while let chunk = try await iterator.next() {
        data.append(chunk)
        if data.count >= limit {
            break
        }
    }

    return data
}
