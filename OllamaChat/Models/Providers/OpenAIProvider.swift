//
//  OpenAIProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class OpenAIProvider: ObservableObject, ChatCompletionAbility {
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
            throw ChatCompletionError.invalidConfiguration("API key is required for OpenAI")
        }

        // Prepare the request URL
        let baseURL = configuration.endpoint.isEmpty ? "https://api.openai.com/v1" : configuration.endpoint
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw ChatCompletionError.invalidConfiguration("Invalid OpenAI endpoint URL")
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
            "temperature": 0.7
        ]

        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

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
            throw ChatCompletionError.unknownError(NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
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
                    throw ChatCompletionError.unknownError(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI API error: \(errorString)"]))
                }
            } else {
                throw ChatCompletionError.unknownError(NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
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
                    let chunk = try JSONDecoder().decode(OpenAIChunk.self, from: jsonData)
                    if let content = chunk.choices.first?.delta.content {
                        continuation.yield(ChatStreamChunk(content: content))
                    }
                } catch {
                    // Continue processing other lines if one fails
                    continue
                }
            }
        }

        continuation.finish()
    }
}

// MARK: - Data Models

private struct OpenAIChunk: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]

    struct Choice: Codable {
        let index: Int?
        let delta: Delta
        let finish_reason: String?

        struct Delta: Codable {
            let role: String?
            let content: String?
        }
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
