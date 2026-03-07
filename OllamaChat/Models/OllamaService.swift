//
//  OllamaService.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

final class OllamaService: ObservableObject {
    private let configuration: OllamaConfiguration
    private let chatOptions: ChatOptions
    private let timeoutRequest: TimeInterval
    private let timeoutResource: TimeInterval
    private var currentTask: Task<Void, Never>?
    
    init(
        configuration: OllamaConfiguration,
        chatOptions: ChatOptions,
        timeoutRequest: TimeInterval,
        timeoutResource: TimeInterval
    ) {
        self.configuration = configuration
        self.chatOptions = chatOptions
        self.timeoutRequest = timeoutRequest
        self.timeoutResource = timeoutResource
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

        let requestBody = ChatModel(
            model: configuration.selectedModel,
            messages: messages,
            options: chatOptions
        )
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        // Create URLSession with custom configuration for streaming
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeoutRequest
        sessionConfig.timeoutIntervalForResource = timeoutResource
        let session = URLSession(configuration: sessionConfig)
        
        // Make the streaming request - use bytes(for:) for streaming responses
        let (bytes, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.networkError(URLError(.badServerResponse))
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw ChatCompletionError.modelNotAvailable(configuration.selectedModel)
            } else if httpResponse.statusCode == 401 {
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
                let chunk = decoded.chatStreamChunk
                if !chunk.isEmpty {
                    continuation.yield(chunk)
                }
            } catch {
                // Continue processing other lines if one fails
                continue
            }
        }
        
        continuation.finish()
    }
}
