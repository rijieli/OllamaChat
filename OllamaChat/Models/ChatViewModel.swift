//
//  ChatViewModel.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

class ChatViewModel: ObservableObject {
    enum Constants {
        static let chatOptionsStorageKey = "ChatViewModel.ChatOptions"
    }

    static let shared = ChatViewModel()
    
    @Published var tags = OllamaModelGroup(models: []) {
        didSet {
            refreshMissingSelectedModelState()
        }
    }
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
        #if os(macOS)
        lastChat = SingleChat.fetchLastCreated()
        #else
        lastChat = nil
        #endif
        if let lastChat {
            messages = lastChat.messages
            currentChat = lastChat
        } else {
            messages = [.globalSystem]
        }

        restoreActiveModelConfiguration(for: lastChat)
    }
    
    @AppStorage("timeoutRequest") var timeoutRequest = "60"
    @AppStorage("timeoutResource") var timeoutResource = "604800"
    
    @Published var chatOptions: ChatOptions {
        didSet {
            guard !isApplyingStoredModelConfiguration else { return }

            UserDefaults.standard.setCodable(chatOptions, forKey: Constants.chatOptionsStorageKey)
            persistCurrentChatModelConfiguration()
        }
    }
    
    @Published var showModelConfiguration = false
    
    @Published var showEditingMessage = false
    
    var editingCellIndex: Int? = nil
    
    @Published var currentChat: SingleChat? = nil {
        didSet {
            refreshMissingSelectedModelState()
        }
    }
    
    @Published var showSettingsView = false
    @Published private(set) var unavailableCurrentChatModelName: String? = nil
    
    @Published var current = ChatMessage(role: .user, content: "")
    
    var model: String {
        if let chatModel = currentChat?.model, !chatModel.isEmpty {
            return chatModel
        }

        let configuredModel = APIManager.shared.selectedModel
        if !configuredModel.isEmpty {
            return configuredModel
        }

        if let fallbackModel = tags.models.first?.name {
            assert(false, "Falling back to the first available Ollama model.")
            return fallbackModel
        }

        return ""
    }

    var requiresModelSelectionOverlay: Bool {
        unavailableCurrentChatModelName != nil
    }

    var availableReplacementModels: [OllamaLanguageModel] {
        tags.models
    }
    
    @Published var messages: [ChatMessage]
    
    @Published var waitingResponse: Bool = false
    
    @Published var errorModel: ErrorModel? = nil
    
    @Published var scrollToBottomToggle = false
    
    private let scrollThrottler = Throttler(interval: 0.1)
    
    private var chatTask: Task<Void, Never>?
    private var ollamaService: OllamaService?
    private var hasResolvedAvailableModelList = false
    
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

                if messages.isEmpty {
                    messages.append(.globalSystem)
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

                APIManager.shared.updateSelectedModel(selectedModel)
                let configuration = APIManager.shared.configuration
                let service = OllamaService(configuration: configuration)
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
                APIManager.shared.updateLastUsed()
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
            messages = [.globalSystem]
            currentChat = nil
        }

        restoreActiveModelConfiguration(for: chat)
        refreshMissingSelectedModelState()
        TextSpeechCenter.shared.stopImmediate()
    }
    
    func newChat() {
        var modelName = APIManager.shared.selectedModel
        if modelName.isEmpty, let fallbackModel = tags.models.first?.name {
            assert(false, "Falling back to the first available Ollama model for a new chat.")
            modelName = fallbackModel
        }

        let modelConfiguration = Self.globalChatOptions()
        let newChat = SingleChat.createNewSingleChat(
            messages: [],
            model: modelName,
            modelConfiguration: modelConfiguration.encodedModelConfiguration()
        )

        CoreDataStack.shared.saveContext()
        loadChat(newChat)
    }

    private func syncConfigurationEndpoint() {
        invalidateAvailableModelList()
        APIManager.shared.updateEndpoint(
            Self.processBaseEndPoint(host: host, port: port)
        )

        Task { @MainActor in
            UnifiedModelRegistry.shared.clearCache()
        }
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
    func updateAvailableModels(_ modelGroup: OllamaModelGroup) {
        hasResolvedAvailableModelList = true
        tags = modelGroup
    }

    @MainActor
    func selectAvailableModel(_ model: String) {
        guard tags.models.contains(where: { $0.name == model }) else {
            assert(false, "Selected replacement model is not in the current Ollama model list.")
            return
        }

        APIManager.shared.updateSelectedModel(model)
        APIManager.shared.updateLastUsed()

        if let currentChat {
            currentChat.model = model
            currentChat.modelConfiguration = currentModelConfiguration.encodedModelConfiguration()
            CoreDataStack.shared.saveContext()
        }

        refreshMissingSelectedModelState()
        objectWillChange.send()
    }

    @MainActor
    func openModelSettings() {
        SettingsViewModel.shared.selectedTab = .ollama
        SettingsViewModel.shared.selectedOllamaSubTab = .models
        showSettingsView = true
    }

    private var currentModelConfiguration: ChatOptions {
        chatOptions
    }

    private static func globalChatOptions() -> ChatOptions {
        UserDefaults.standard.getCodable(forKey: Constants.chatOptionsStorageKey) ?? .defaultValue
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

    private func invalidateAvailableModelList() {
        hasResolvedAvailableModelList = false
        unavailableCurrentChatModelName = nil
        tags = OllamaModelGroup(models: [])
    }

    private func refreshMissingSelectedModelState() {
        guard hasResolvedAvailableModelList,
              let chatModel = currentChat?.model,
              !chatModel.isEmpty
        else {
            unavailableCurrentChatModelName = nil
            return
        }

        let availableModels = Set(tags.models.map(\.name))
        unavailableCurrentChatModelName = availableModels.contains(chatModel) ? nil : chatModel
    }
}
