//
//  LLMAgent.swift
//  OllamaChat
//
//  Created by Claude on 2025-12-10.
//

import Foundation
import SwiftUI

// MARK: - LLMAgent Errors
enum LLMAgentError: Error, LocalizedError {
    case noConfigurationAvailable
    case configurationNotValid
    case providerNotAvailable
    case requestCancelled
    case modelNotAvailable

    var errorDescription: String? {
        switch self {
        case .noConfigurationAvailable:
            return NSLocalizedString(
                "No AI configuration available. Please set up a provider in settings.",
                comment: "Error message when no AI configuration is available"
            )
        case .configurationNotValid:
            return NSLocalizedString(
                "The current configuration is invalid.",
                comment: "Error message for invalid configuration"
            )
        case .providerNotAvailable:
            return NSLocalizedString(
                "The AI provider is not available.",
                comment: "Error message when provider is unavailable"
            )
        case .requestCancelled:
            return NSLocalizedString(
                "Request was cancelled.",
                comment: "Error message for cancelled request"
            )
        case .modelNotAvailable:
            return NSLocalizedString(
                "The selected model is not available.",
                comment: "Error message for unavailable model"
            )
        }
    }
}

// MARK: - Main LLMAgent Class
@MainActor
class LLMAgent: ObservableObject {

    static let shared = LLMAgent()

    // MARK: - Published Properties
    /// Complete conversation history including all messages
    @Published var messages: [ChatMessage] = []

    /// Currently receiving streaming message
    @Published var receivingMessage: ChatMessage? = nil

    /// Loading state for UI indicators
    @Published var isLoading: Bool = false

    /// Current error state
    @Published var error: Error? = nil

    /// Current chat ID for tracking
    @Published var currentChatId: UUID? = nil

    // MARK: - Private Properties
    private var currentTask: Task<Void, Error>?
    private var currentProvider: (any ChatCompletionAbility)?
    private var _currentConfiguration: ChatCompletion?

    // MARK: - Dependencies
    private let apiManager: APIManager

    // MARK: - Initialization
    private init(apiManager: APIManager = .shared) {
        self.apiManager = apiManager
    }

    // MARK: - Public Interface

    /// Send a user message and receive streaming response
    /// - Parameter userMessage: The user message to send
    /// - Throws: LLMAgentError or provider-specific errors
    func send(userMessage: ChatMessage) async throws {
        // Cancel any existing request
        await cancel()

        // Get configuration
        guard let configuration = await getConfiguration() else {
            throw LLMAgentError.noConfigurationAvailable
        }

        // Create provider
        let provider = try apiManager.createProvider(for: configuration)

        // Update state
        _currentConfiguration = configuration
        currentProvider = provider
        isLoading = true
        error = nil

        // Add user message to history
        messages.append(userMessage)

        // Create assistant message
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        receivingMessage = assistantMessage

        // Create and track task
        currentTask = Task<Void, Error> {
            isLoading = true
            error = nil

            // 使用 defer 确保清理代码总是执行
            defer {
                Task { @MainActor in
                    isLoading = false
                    receivingMessage = nil
                    currentTask = nil
                    currentProvider = nil
                }
            }

            do {
                // Send request
                let stream = try await provider.send(messages: messages)

                // Process stream
                for try await chunk in stream {
                    guard !Task.isCancelled else { throw LLMAgentError.requestCancelled }
                    receivingMessage?.content += chunk
                }

                // Add complete assistant message to history
                if let finalMessage = receivingMessage {
                    messages.append(finalMessage)
                }

                // Update last used
                apiManager.updateLastUsed(id: configuration.id)

                // Save to Core Data
                await saveChat()

            } catch {
                self.error = error
                throw error
            }
        }

        // Wait for completion
        try await currentTask?.value

        // Propagate error if any
        if let error = error {
            throw error
        }
    }

    /// Load existing chat messages
    /// - Parameter chat: The SingleChat entity to load
    func loadChat(_ chat: SingleChat) {
        messages = chat.messages
        currentChatId = chat.id
    }

    /// Start a new chat
    func startNewChat() {
        messages = [.globalSystem]
        currentChatId = nil
    }

    /// Clear all messages and start fresh
    func clearMessages() {
        messages = [.globalSystem]
    }

    // MARK: - Computed Properties
    /// Current active configuration
    var currentConfiguration: ChatCompletion? {
        return _currentConfiguration ?? apiManager.defaultCompletion
    }

    /// All available configurations
    var allConfigurations: [ChatCompletion] {
        return apiManager.completions
    }

    /// Cancel the current streaming request
    func cancel() async {
        currentTask?.cancel()
        await currentProvider?.cancel()

        await MainActor.run {
            currentTask = nil
            currentProvider = nil
            isLoading = false
            receivingMessage = nil
        }
    }

    /// Switch to a different provider configuration
    /// - Parameter configuration: The new ChatCompletion configuration
    /// - Throws: LLMAgentError if configuration is invalid
    func switchToConfiguration(_ configuration: ChatCompletion) throws {
        // Validate configuration
        try ProviderFactory.validateConfiguration(configuration)

        // Set as default
        apiManager.setDefaultConfiguration(configuration)

        // Cancel current request
        Task {
            await cancel()
        }
    }

    /// Switch to a different model within current configuration
    /// - Parameter modelName: The name of the model to switch to
    /// - Throws: LLMAgentError if model is not available
    func switchToModel(_ modelName: String) throws {
        guard var configuration = currentConfiguration else {
            throw LLMAgentError.noConfigurationAvailable
        }

        // Validate model exists
        guard configuration.models.contains(modelName) else {
            throw LLMAgentError.modelNotAvailable
        }

        // Update configuration
        configuration.selectedModel = modelName
        try ProviderFactory.validateConfiguration(configuration)

        // Save changes
        try apiManager.updateConfiguration(configuration)
        _currentConfiguration = configuration
    }

    // MARK: - Private Helpers
    private func getConfiguration() async -> ChatCompletion? {
        // Priority: current config > default > first available
        return _currentConfiguration ?? apiManager.defaultCompletion ?? apiManager.enabledConfigurations.first
    }

    /// Save current chat to Core Data
    private func saveChat() async {
        if let chatId = currentChatId {
            // Update existing chat
            if let chat = SingleChat.fetch(by: chatId) {
                chat.messages = messages
                chat.model = currentConfiguration?.selectedModel ?? ""
            }
        } else {
            // Create new chat
            let newChat = SingleChat.createNewSingleChat(
                messages: messages,
                model: currentConfiguration?.selectedModel ?? ""
            )
            currentChatId = newChat.id
        }

        CoreDataStack.shared.saveContext()
    }
}
