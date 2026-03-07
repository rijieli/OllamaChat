//
//  AnthropicProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class AnthropicProvider: ObservableObject, ChatCompletionAbility {
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
            throw ChatCompletionError.invalidConfiguration("API key is required for Anthropic")
        }

        // Prepare the request URL
        let baseURL = configuration.endpoint.isEmpty ? "https://api.anthropic.com/v1" : configuration.endpoint
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw ChatCompletionError.invalidConfiguration("Invalid Anthropic endpoint URL")
        }

        // Convert messages to Anthropic format
        // Anthropic requires alternating user/assistant messages, starting with user
        let anthropicMessages = convertToAnthropicFormat(messages)

        // Prepare request body
        let requestBody: [String: Any] = [
            "model": configuration.selectedModel,
            "messages": anthropicMessages,
            "max_tokens": 4096,
            "stream": true
        ]

        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

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
            throw ChatCompletionError.unknownError(NSError(domain: "Anthropic", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard httpResponse.statusCode == 200 else {
            // Try to read error details
            if let errorData = try? await bytesData(bytes, upTo: 1024),
               let errorString = String(data: errorData, encoding: .utf8) {
                if httpResponse.statusCode == 401 {
                    throw ChatCompletionError.authenticationError
                } else if httpResponse.statusCode == 429 {
                    throw ChatCompletionError.rateLimitError
                } else {
                    throw ChatCompletionError.unknownError(NSError(domain: "Anthropic", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Anthropic API error: \(errorString)"]))
                }
            } else {
                throw ChatCompletionError.unknownError(NSError(domain: "Anthropic", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
            }
        }

        // Process streaming response
        var currentEvent: String?
        var eventData = ""

        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }

            // Parse SSE format
            if line.hasPrefix("event: ") {
                currentEvent = String(line.dropFirst(7))
            } else if line.hasPrefix("data: ") {
                eventData = String(line.dropFirst(6))

                // Process events
                if let event = currentEvent, event == "content_block_delta" {
                    guard let jsonData = eventData.data(using: .utf8) else { continue }

                    do {
                        let chunk = try JSONDecoder().decode(AnthropicChunk.self, from: jsonData)
                        if let delta = chunk.delta, let text = delta.text {
                            continuation.yield(ChatStreamChunk(content: text))
                        }
                    } catch {
                        // Continue processing other lines if one fails
                        continue
                    }
                } else if eventData == "[DONE]" {
                    continuation.finish()
                    return
                }
            }
        }

        continuation.finish()
    }

    private func convertToAnthropicFormat(_ messages: [ChatMessage]) -> [[String: Any]] {
        var anthropicMessages: [[String: Any]] = []
        var currentContent: [String] = []

        for message in messages {
            if message.role == .user {
                // If we have accumulated content from previous assistant messages, add it
                if !currentContent.isEmpty {
                    anthropicMessages.append([
                        "role": "assistant",
                        "content": currentContent.joined()
                    ])
                    currentContent = []
                }
                anthropicMessages.append([
                    "role": "user",
                    "content": message.content
                ])
            } else {
                // Accumulate assistant content
                currentContent.append(message.content)
            }
        }

        // Add any remaining assistant content
        if !currentContent.isEmpty {
            anthropicMessages.append([
                "role": "assistant",
                "content": currentContent.joined()
            ])
        }

        return anthropicMessages
    }
}

// MARK: - Data Models

private struct AnthropicChunk: Codable {
    let type: String?
    let index: Int?
    let delta: Delta?

    struct Delta: Codable {
        let type: String?
        let text: String?
    }
}

// Helper function to read bytes from AsyncBytes
private func bytesData(_ bytes: URLSession.AsyncBytes, upTo limit: Int) async throws -> Data {
    var data = Data()
    var iterator = bytes.makeAsyncIterator()

    while let chunk = try await iterator.next(), data.count < limit {
        data.append(chunk)
    }

    return data
}
