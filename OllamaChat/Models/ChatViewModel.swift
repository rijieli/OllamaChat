//
//  ChatViewModel.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

class ChatViewModel: ObservableObject {
    
    static let shared = ChatViewModel()
    
    @Published var tags = OllamaModelGroup(models: [])
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

    private init() {
        let endpointComponents = Self.endpointComponents(from: APIManager.shared.endpoint)
        host = endpointComponents.host
        port = endpointComponents.port

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
    }
    
    @AppStorage("timeoutRequest") var timeoutRequest = "60"
    @AppStorage("timeoutResource") var timeoutResource = "604800"
    @AppStorage("ChatViewModel.OllamaThinkMode")
    private var ollamaThinkModeRawValue = OllamaThinkMode.automatic.rawValue
    
    @Published var chatOptions: ChatOptions = {
        UserDefaults.standard.getCodable(forKey: "ChatViewModel.ChatOptions") ?? .defaultValue
    }()
    {
        didSet {
            UserDefaults.standard.setCodable(chatOptions, forKey: "ChatViewModel.ChatOptions")
        }
    }
    
    @Published var showSystemConfig = false
    
    @Published var showEditingMessage = false
    
    var editingCellIndex: Int? = nil
    
    @Published var currentChat: SingleChat? = nil
    
    @Published var showSettingsView = false
    
    @Published var current = ChatMessage(role: .user, content: "")

    var ollamaThinkMode: OllamaThinkMode {
        get {
            let thinkMode = OllamaThinkMode(rawValue: ollamaThinkModeRawValue)
            assert(thinkMode != nil, "Unknown Ollama think mode: \(ollamaThinkModeRawValue)")
            return thinkMode ?? .automatic
        }
        set {
            ollamaThinkModeRawValue = newValue.rawValue
        }
    }

    var ollamaThinkRequestValue: OllamaThinkRequestValue? {
        ollamaThinkMode.requestValue
    }
    
    var model: String {
        if let chatModel = currentChat?.model, !chatModel.isEmpty {
            let availableModels = Set(tags.models.map(\.name))
            if availableModels.isEmpty || availableModels.contains(chatModel) {
                return chatModel
            }
            assert(false, "Current chat model is unavailable in the current Ollama model list.")
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
    
    @Published var messages: [ChatMessage]
    
    @Published var waitingResponse: Bool = false
    
    @Published var errorModel: ErrorModel? = nil
    
    @Published var scrollToBottomToggle = false
    
    private let scrollThrottler = Throttler(interval: 0.1)
    
    private var chatTask: Task<Void, Never>?
    private var ollamaService: OllamaService?
    
    @MainActor
    func send() {
        chatTask = Task {
            guard let chatID = currentChat?.id else { return }
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
                    if chatID != currentChat?.id {
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
                } else {
                    let newChat = SingleChat.createNewSingleChat(messages: messages, model: configuration.selectedModel)
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
        showSystemConfig = false
    }
    
    func saveDataToDatabase() {
        if let chat = currentChat {
            chat.messages = messages
            chat.model = model
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
        TextSpeechCenter.shared.stopImmediate()
    }
    
    func newChat() {
        var modelName = APIManager.shared.selectedModel
        if modelName.isEmpty, let fallbackModel = tags.models.first?.name {
            assert(false, "Falling back to the first available Ollama model for a new chat.")
            modelName = fallbackModel
        }

        let newChat = SingleChat.createNewSingleChat(
            messages: [],
            model: modelName
        )

        CoreDataStack.shared.saveContext()
        loadChat(newChat)
    }

    private func syncConfigurationEndpoint() {
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
}
