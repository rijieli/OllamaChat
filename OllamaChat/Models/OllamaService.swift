//
//  OllamaService.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

final class OllamaService: ObservableObject {
    private struct OllamaErrorResponse: Decodable {
        let error: String
    }

    private let configuration: OllamaConfiguration
    private let chatConfiguration: ChatConfiguration
    private let allowsThinkingRequests: Bool
    private let timeoutRequest: TimeInterval
    private let timeoutResource: TimeInterval
    private var currentTask: Task<Void, Never>?
    
    init(
        configuration: OllamaConfiguration,
        chatConfiguration: ChatConfiguration,
        allowsThinkingRequests: Bool,
        timeoutRequest: TimeInterval,
        timeoutResource: TimeInterval
    ) {
        self.configuration = configuration
        self.chatConfiguration = chatConfiguration
        self.allowsThinkingRequests = allowsThinkingRequests
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
        
        // Create URLSession with custom configuration for streaming
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeoutRequest
        sessionConfig.timeoutIntervalForResource = timeoutResource
        let session = URLSession(configuration: sessionConfig)
        
        let bytes = try await openChatStream(
            messages: messages,
            requestURL: requestURL,
            session: session,
            includeThinkField: allowsThinkingRequests
        )
        
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

    private func openChatStream(
        messages: [ChatMessage],
        requestURL: URL,
        session: URLSession,
        includeThinkField: Bool = true
    ) async throws -> URLSession.AsyncBytes {
        let request = try makeRequest(
            requestURL: requestURL,
            messages: messages,
            includeThinkField: includeThinkField
        )
        let (bytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChatCompletionError.networkError(URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let serverMessage = try await serverErrorMessage(from: bytes)
            log.error("Ollama HTTP \(httpResponse.statusCode): \(serverMessage ?? "No response body")")
            throw mapHTTPError(statusCode: httpResponse.statusCode, serverMessage: serverMessage)
        }

        return bytes
    }

    private func makeRequest(
        requestURL: URL,
        messages: [ChatMessage],
        includeThinkField: Bool
    ) throws -> URLRequest {
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ChatModel(
            model: configuration.selectedModel,
            messages: messages,
            configuration: Self.requestConfiguration(
                from: chatConfiguration,
                includeThinkField: includeThinkField
            )
        )
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        return request
    }

    static func requestConfiguration(
        from configuration: ChatConfiguration,
        includeThinkField: Bool
    ) -> ChatConfiguration {
        guard includeThinkField else {
            return ChatConfiguration(think: .automatic, options: configuration.options)
        }

        return configuration
    }

    private func mapHTTPError(
        statusCode: Int,
        serverMessage: String?
    ) -> ChatCompletionError {
        switch statusCode {
        case 401:
            return .authenticationError
        case 404:
            return .modelNotAvailable(configuration.selectedModel)
        case 429:
            return .rateLimitError
        default:
            return .serverError(statusCode: statusCode, message: serverMessage)
        }
    }

    private func serverErrorMessage(from bytes: URLSession.AsyncBytes) async throws -> String? {
        var data = Data()
        data.reserveCapacity(512)

        for try await byte in bytes {
            data.append(contentsOf: [byte])

            if data.count >= 32_768 {
                break
            }
        }

        guard !data.isEmpty else { return nil }

        if let decoded = try? JSONDecoder().decode(OllamaErrorResponse.self, from: data) {
            let message = decoded.error.trimmingCharacters(in: .whitespacesAndNewlines)
            return message.isEmpty ? nil : message
        }

        let message = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return message?.isEmpty == true ? nil : message
    }
}
