//
//  ChatViewModel.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

    @Published var host: String {
        didSet {
            syncConfigurationEndpoint()
        }
    }
    @Published var port: String {
        didSet {
            syncConfigurationEndpoint()
        }
    }

    private var isApplyingStoredModelConfiguration = false

    private init() {
        let endpointComponents = Self.endpointComponents(from: APIManager.shared.endpoint)
        host = endpointComponents.host
        port = endpointComponents.port
        chatOptions = Self.globalChatOptions()

        let lastChat: SingleChat?
        lastChat = SingleChat.fetchLastCreated()
        if let lastChat {
            messages = lastChat.messages
            currentChat = lastChat
        } else {
            messages = Self.defaultMessages()
        }

        restoreActiveModelConfiguration(for: lastChat)
    }
    
    @AppStorage("timeoutRequest") var timeoutRequest = "60"
    @AppStorage("timeoutResource") var timeoutResource = "604800"
    
    @Published var chatOptions: ChatOptions {
        didSet {
            guard !isApplyingStoredModelConfiguration else { return }

            persistCurrentChatModelConfiguration()
        }
    }
    
    @Published var showModelConfiguration = false
    
    @Published var showEditingMessage = false
    
    var editingCellIndex: Int? = nil
    
    @Published var currentChat: SingleChat? = nil
    
    @Published var showSettingsView = false

    var unavailableCurrentChatModelName: String? {
        guard UnifiedModelRegistry.shared.hasResolvedModels,
              let chatModel = currentChat?.model,
              !chatModel.isEmpty
        else {
            return nil
        }

        let availableModels = Set(UnifiedModelRegistry.shared.models.map(\.name))
        return availableModels.contains(chatModel) ? nil : chatModel
    }
    
    @Published var current = ChatMessage(role: .user, content: "")
    
    var model: String {
        if let chatModel = currentChat?.model, !chatModel.isEmpty {
            return chatModel
        }

        if let fallbackModel = UnifiedModelRegistry.shared.models.first?.name {
            assert(false, "Falling back to the first available Ollama model.")
            return fallbackModel
        }

        return ""
    }

    var requiresModelSelectionOverlay: Bool {
        unavailableCurrentChatModelName != nil
    }

    var availableReplacementModels: [OllamaLanguageModel] {
        UnifiedModelRegistry.shared.models
    }
    
    @Published var messages: [ChatMessage]
    
    @Published var waitingResponse: Bool = false
    
    @Published var errorModel: ErrorModel? = nil
    
    @Published var scrollToBottomToggle = false
    
    private let scrollThrottler = Throttler(interval: 0.1)
    
    private var chatTask: Task<Void, Never>?
    private var ollamaService: OllamaService?
    
    @MainActor
    func send() {
        guard !requiresModelSelectionOverlay else { return }

        chatTask = Task {
            let chatID = currentChat?.id
            do {
                self.errorModel = nil
                waitingResponse = true
                defer {
                    waitingResponse = false
                    ollamaService = nil
                }

                if !current.content.isEmpty {
                    self.messages.append(current)
                    scrollToBottom()
                }

                current = .init(role: .user, content: "")

                let selectedModel = model
                if selectedModel.isEmpty {
                    errorModel = noModelsError(error: nil)
                    return
                }

                var configuration = APIManager.shared.configuration
                configuration.selectedModel = selectedModel
                let service = OllamaService(
                    configuration: configuration,
                    chatOptions: currentModelConfiguration,
                    timeoutRequest: Double(timeoutRequest) ?? 60,
                    timeoutResource: Double(timeoutResource) ?? 604800
                )
                ollamaService = service

                print("[Sending] <\(configuration.selectedModel)> \(messages.last?.content.count ?? 0)")

                let stream = try await service.send(messages: messages)

                let assistantMessage = ChatMessage(role: .assistant, content: "")
                messages.append(assistantMessage)

                for try await chunk in stream {
                    if let chatID, chatID != currentChat?.id {
                        CoreDataStack.shared.saveContext()
                        break
                    }

                    if chunk.isEmpty {
                        continue
                    }

                    if let index = messages.lastIndex(where: { $0.id == assistantMessage.id }) {
                        messages[index].append(chunk)
                        scrollThrottler.call {
                            self.scrollToBottom()
                        }
                    }
                }

                if let currentChat {
                    currentChat.messages = messages
                    currentChat.model = configuration.selectedModel
                    currentChat.modelConfiguration = currentModelConfiguration.encodedModelConfiguration()
                } else {
                    let newChat = SingleChat.createNewSingleChat(
                        messages: messages,
                        model: configuration.selectedModel,
                        modelConfiguration: currentModelConfiguration.encodedModelConfiguration()
                    )
                    currentChat = newChat
                }

                CoreDataStack.shared.saveContext()
            } catch {
                handleError(error)
            }
        }
    }

    @MainActor
    func resendUntil(_ message: ChatMessage) {
        guard !requiresModelSelectionOverlay else { return }
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        waitingResponse = false
        chatTask?.cancel()
        if idx < messages.endIndex {
            messages = Array(messages[...idx])
        }
        current = .init(role: .user, content: "")
        if messages.last?.role == .user {
            send()
        }
    }
    
    func cancelTask() {
        chatTask?.cancel()
        Task {
            await ollamaService?.cancel()
        }
        waitingResponse = false
        clearError()
    }
    
    func scrollToBottom() {
        DispatchQueue.main.async {
            self.scrollToBottomToggle.toggle()
        }
    }
    
    func editMessage(_ message: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        editingCellIndex = idx
        showEditingMessage = true
    }
    
    func updateMessage(at index: Int, with newMessage: ChatMessage) {
        // Ensure the index is within bounds
        guard messages.indices.contains(index) else { return }
        
        // Update the content of the message
        messages[index] = newMessage
        saveDataToDatabase()
    }
    
    func updateSystem(_ newSystem: ChatMessage) {
        if let idx = messages.firstIndex(where: { $0.role == .system }) {
            messages[idx] = newSystem
        } else {
            messages.insert(newSystem, at: 0)
        }
        saveDataToDatabase()
        showModelConfiguration = false
    }
    
    func saveDataToDatabase() {
        if let chat = currentChat {
            chat.messages = messages
            let persistedModel = chat.model.isEmpty ? model : chat.model
            chat.model = persistedModel
            chat.modelConfiguration = currentModelConfiguration.encodedModelConfiguration()
            CoreDataStack.shared.saveContext()
        }
    }
    
    func loadChat(_ chat: SingleChat?) {
        if let chat {
            messages = chat.messages
            currentChat = chat
        } else {
            messages = Self.defaultMessages()
            currentChat = nil
        }

        restoreActiveModelConfiguration(for: chat)
        TextSpeechCenter.shared.stopImmediate()
    }
    
    func newChat() {
        let modelName: String
        if let firstModel = UnifiedModelRegistry.shared.models.first?.name {
            modelName = firstModel
        } else {
            assert(false, "Creating a new chat without an available Ollama model.")
            modelName = ""
        }

        let modelConfiguration = Self.globalChatOptions()
        let newChat = SingleChat.createNewSingleChat(
            messages: Self.defaultMessages(),
            model: modelName,
            modelConfiguration: modelConfiguration.encodedModelConfiguration()
        )

        CoreDataStack.shared.saveContext()
        loadChat(newChat)
    }

    private func syncConfigurationEndpoint() {
        APIManager.shared.updateEndpoint(
            Self.processBaseEndPoint(host: host, port: port)
        )
        UnifiedModelRegistry.shared.invalidateModels()
    }
    
    @MainActor
    func handleError(_ error: Error) {
        if let netError = error as? NetError {
            switch netError {
            case .invalidURL(let error):
                errorModel = invalidURLError(error: error)
            case .invalidData(let error):
                errorModel = invalidDataError(error: error)
            case .invalidResponse(let error):
                errorModel = invalidResponseError(error: error)
            case .unreachable(let error):
                errorModel = unreachableError(error: error)
            case .general(let error):
                errorModel = genericError(error: error)
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                break
            case .timedOut:
                errorModel = invalidResponseError(error: error)
            default:
                errorModel = genericError(error: error)
            }
            log.error("Chat Error: \(error.localizedDescription)")
        } else {
            errorModel = genericError(error: error)
        }
    }
    
    func clearError() {
        if errorModel != nil {
            DispatchQueue.main.async { [weak self] in
                self?.errorModel = nil
            }
        }
    }

    @MainActor
    func selectAvailableModel(_ model: String) {
        guard UnifiedModelRegistry.shared.models.contains(where: { $0.name == model }) else {
            assert(false, "Selected replacement model is not in the current Ollama model list.")
            return
        }

        if let currentChat {
            currentChat.model = model
            currentChat.modelConfiguration = currentModelConfiguration.encodedModelConfiguration()
            CoreDataStack.shared.saveContext()
        } else {
            assert(false, "Cannot select a model without an active chat.")
        }

        objectWillChange.send()
    }

    @MainActor
    func openModelSettings() {
        SettingsViewModel.shared.selectedTab = .models
        showSettingsView = true
    }

    private var currentModelConfiguration: ChatOptions {
        chatOptions
    }

    private static func globalChatOptions() -> ChatOptions {
        AppSettings.defaultChatOptions
    }

    private static func defaultMessages() -> [ChatMessage] {
        let systemPrompt = AppSettings.globalSystem
        guard !systemPrompt.isEmpty else { return [] }
        return [.init(role: .system, content: systemPrompt)]
    }

    private func restoreActiveModelConfiguration(for chat: SingleChat?) {
        if let chatModelConfiguration = chat?.chatModelConfiguration {
            applyModelConfiguration(chatModelConfiguration)
            return
        }

        applyModelConfiguration(Self.globalChatOptions())
    }

    private func applyModelConfiguration(_ modelConfiguration: ChatOptions) {
        isApplyingStoredModelConfiguration = true
        chatOptions = modelConfiguration
        isApplyingStoredModelConfiguration = false
    }

    private func persistCurrentChatModelConfiguration() {
        guard let currentChat else { return }

        currentChat.modelConfiguration = currentModelConfiguration.encodedModelConfiguration()
        CoreDataStack.shared.saveContext()
    }
}
