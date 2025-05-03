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
    
    private init() {
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
    
    @Published var tags = OllamaModelGroup(models: [])
    
    @AppStorage("host") var host = "http://127.0.0.1"
    @AppStorage("port") var port = "11434"
    @AppStorage("timeoutRequest") var timeoutRequest = "60"
    @AppStorage("timeoutResource") var timeoutResource = "604800"
    
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
    
    var model: String {
        let modelName = currentChat?.model
        if let modelName,
            tags.models.contains(where: { $0.name == modelName })
        {
            return modelName
        } else {
            return tags.models.first?.name ?? ""
        }
    }
    
    @Published var messages: [ChatMessage]
    
    @Published var waitingResponse: Bool = false
    
    @Published var errorModel: ErrorModel? = nil
    
    @Published var scrollToBottomToggle = false
    
    private let scrollThrottler = Throttler(interval: 0.1)
    
    private var chatTask: Task<Void, Never>?
    
    @MainActor
    func send() {
        chatTask = Task {
            guard let chatID = currentChat?.id else { return }
            do {
                self.errorModel = nil
                waitingResponse = true
                
                if messages.isEmpty {
                    messages.append(.globalSystem)
                }
                
                if !current.content.isEmpty {
                    self.messages.append(current)
                    scrollToBottom()
                }
                
                current = .init(role: .user, content: "")
                
                let filterdModel = self.model
                
                if filterdModel.isEmpty {
                    waitingResponse = false
                    errorModel = noModelsError(error: nil)
                    return
                }
                
                let chatHistory = ChatModel(
                    model: filterdModel,
                    messages: messages,
                    options: chatOptions
                )
                
                let endpoint = APIEndPoint + "chat"
                
                guard let url = URL(string: endpoint) else {
                    throw NetError.invalidURL(error: nil)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let encoder = JSONEncoder()
                let httpBody = try encoder.encode(chatHistory)
                request.httpBody = httpBody
                
                print("[Sending] <\(chatHistory.model)> \(messages.last?.content.count ?? 0)")
                
                let data: URLSession.AsyncBytes
                let response: URLResponse
                
                do {
                    let sessionConfig = URLSessionConfiguration.default
                    sessionConfig.timeoutIntervalForRequest = Double(timeoutRequest) ?? 60
                    sessionConfig.timeoutIntervalForResource = Double(timeoutResource) ?? 604800
                    (data, response) = try await URLSession(configuration: sessionConfig).bytes(
                        for: request
                    )
                } catch {
                    throw NetError.unreachable(error: error)
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw NetError.invalidResponse(error: nil)
                }
                
                let decoder = JSONDecoder()
                let message = ChatMessage(role: .assistant, content: "")
                for try await line in data.lines {
                    guard !line.isEmpty else { continue }
                    
                    if chatID != currentChat?.id {
                        CoreDataStack.shared.saveContext()
                        break
                    }
                    
                    if messages.last?.id != message.id {
                        messages.append(message)
                    }
                    let data = line.data(using: .utf8)!
                    let decoded = try! decoder.decode(ResponseModel.self, from: data)
                    if let index = self.messages.lastIndex(where: { $0.id == message.id }) {
                        self.messages[index].content += decoded.message.content
                    }
                    scrollThrottler.call {
                        self.scrollToBottom()
                    }
                }
                
                waitingResponse = false
                if let currentChat {
                    currentChat.messages = messages
                    currentChat.model = filterdModel
                } else {
                    let newChat = SingleChat.createNewSingleChat(messages: messages, model: model)
                    newChat.model = filterdModel
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
        let newChat = SingleChat.createNewSingleChat(
            messages: [],
            model: tags.models.first?.name ?? ""
        )
        CoreDataStack.shared.saveContext()
        loadChat(newChat)
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
