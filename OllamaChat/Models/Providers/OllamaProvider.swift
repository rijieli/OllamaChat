//
//  OllamaProvider.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class OllamaProvider: ObservableObject, ChatCompletionAbility {
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
        // Parse the endpoint to extract host and port
        guard let url = URL(string: configuration.endpoint) else {
            throw ChatCompletionError.invalidConfiguration("Invalid Ollama endpoint URL")
        }
        
        let host = url.host ?? "127.0.0.1"
        let port = url.port ?? 11434
        
        // Build the API endpoint
        let apiEndpoint = "\(url.scheme ?? "http")://\(host):\(port)/api/chat"
        
        guard let requestURL = URL(string: apiEndpoint) else {
            throw ChatCompletionError.invalidConfiguration("Cannot build API endpoint URL")
        }
        
        // Prepare the request
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert messages to Ollama format
        let ollamaMessages = messages.map { message in
            [
                "role": message.role == .user ? "user" : "assistant",
                "content": message.content,
            ]
        }
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": configuration.selectedModel,
            "messages": ollamaMessages,
            "stream": true,
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw ChatCompletionError.invalidConfiguration("Cannot serialize request body")
        }
        
        request.httpBody = jsonData
        
        // Create URLSession with custom configuration for streaming
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 60
        sessionConfig.timeoutIntervalForResource = 604800  // Long timeout for long-running responses
        let session = URLSession(configuration: sessionConfig)
        
        // Make the streaming request - use bytes(for:) for streaming responses
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ChatCompletionError.authenticationError
            } else if httpResponse.statusCode == 429 {
                throw ChatCompletionError.rateLimitError
            } else {
                throw ChatCompletionError.networkError(
                    URLError(.init(rawValue: httpResponse.statusCode))
                )
            }
        }
        
        // Process streaming response line by line
        // Ollama returns each JSON object on a separate line (not SSE format with "data: " prefix)
        let decoder = JSONDecoder()
        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }
            
            // Each line is a complete JSON object that can be decoded as ResponseModel
            guard let lineData = line.data(using: .utf8) else { continue }
            
            do {
                let decoded = try decoder.decode(ResponseModel.self, from: lineData)
                // Extract the content from the message
                continuation.yield(decoded.message.content)
            } catch {
                // Continue processing other lines if one fails
                continue
            }
        }
        
        continuation.finish()
    }
}
