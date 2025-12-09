//
//  GeminiProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class GeminiProvider: ObservableObject, ChatCompletionAbility {
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
            throw ChatCompletionError.invalidConfiguration("API key is required for Gemini")
        }

        // Gemini API key is passed as a query parameter
        var urlString: String
        if configuration.endpoint.isEmpty {
            urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(configuration.selectedModel):streamGenerateContent?key=\(apiKey)"
        } else {
            // For custom endpoints, append API key as query parameter
            let baseEndpoint = configuration.endpoint.hasSuffix(":streamGenerateContent") ? configuration.endpoint : "\(configuration.endpoint):streamGenerateContent"
            urlString = "\(baseEndpoint)?key=\(apiKey)"
        }

        guard let url = URL(string: urlString) else {
            throw ChatCompletionError.invalidConfiguration("Invalid Gemini endpoint URL")
        }

        // Convert messages to Gemini format
        let contents = convertToGeminiFormat(messages)

        // Prepare request body
        let requestBody: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 4096
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                ]
            ]
        ]

        // Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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
            throw ChatCompletionError.unknownError(NSError(domain: "Gemini", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        guard httpResponse.statusCode == 200 else {
            // Try to read error details
            if let errorData = try? await bytesData(bytes, upTo: 1024),
               let errorString = String(data: errorData, encoding: .utf8) {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    throw ChatCompletionError.authenticationError
                } else if httpResponse.statusCode == 429 {
                    throw ChatCompletionError.rateLimitError
                } else {
                    throw ChatCompletionError.unknownError(NSError(domain: "Gemini", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini API error: \(errorString)"]))
                }
            } else {
                throw ChatCompletionError.unknownError(NSError(domain: "Gemini", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"]))
            }
        }

        // Process streaming response
        // Gemini returns a series of JSON objects, each wrapped in array brackets
        var buffer = ""
        for try await byte in bytes {
            let chunk = String(bytes: [byte], encoding: .utf8) ?? ""
            buffer += chunk

            // Try to extract complete JSON objects from the buffer
            while true {
                // Look for object start and end
                guard let objectStart = buffer.firstIndex(of: "{") else { break }
                guard let objectEnd = buffer.firstIndex(of: "}") else { break }

                // Extract the JSON object
                let startIndex = buffer.index(after: objectStart)
                let endIndex = buffer.index(objectEnd, offsetBy: 1)
                let jsonString = String(buffer[startIndex..<endIndex])

                // Remove the processed part from buffer
                buffer = String(buffer[endIndex...])

                // Parse the JSON object
                guard let jsonData = jsonString.data(using: .utf8) else { continue }

                do {
                    let response = try JSONDecoder().decode(GeminiResponse.self, from: jsonData)

                    // Extract text from candidates
                    if let candidate = response.candidates.first,
                       let content = candidate.content,
                       let part = content.parts.first,
                       let text = part.text {
                        continuation.yield(text)
                    }

                    // Check if this is the final response
                    if response.candidates.first?.finishReason != nil {
                        continuation.finish()
                        return
                    }
                } catch {
                    // Continue processing other objects if one fails
                    continue
                }
            }
        }

        continuation.finish()
    }

    private func convertToGeminiFormat(_ messages: [ChatMessage]) -> [[String: Any]] {
        var contents: [[String: Any]] = []

        for message in messages {
            let role = message.role == .user ? "user" : "model"
            contents.append([
                "role": role,
                "parts": [["text": message.content]]
            ])
        }

        return contents
    }
}

// MARK: - Data Models

private struct GeminiResponse: Codable {
    let candidates: [Candidate]
    let promptFeedback: PromptFeedback?

    struct Candidate: Codable {
        let content: Content?
        let finishReason: String?
        let index: Int?
        let safetyRatings: [SafetyRating]?

        struct Content: Codable {
            let parts: [Part]
            let role: String?
        }

        struct Part: Codable {
            let text: String?
        }
    }

    struct PromptFeedback: Codable {
        let blockReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct SafetyRating: Codable {
        let category: String?
        let probability: String?
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