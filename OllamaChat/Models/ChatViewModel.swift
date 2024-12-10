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
        let lastChat = SingleChat.fetchLastCreated()
        if let lastChat {
            messages = lastChat.messages
            model = lastChat.model
            currentChat = lastChat
        } else {
            messages = [.globalSystem]
            model = ""
        }
    }

    @Published var tags = ModelGroup(models: [])

    @AppStorage("host") var host = "http://127.0.0.1"
    @AppStorage("port") var port = "11434"
    @AppStorage("timeoutRequest") var timeoutRequest = "60"
    @AppStorage("timeoutResource") var timeoutResource = "604800"

    @Published var showSystemConfig = false

    @Published var showEditingMessage = false

    var editingCellIndex: Int? = nil

    @Published var currentChat: SingleChat? = nil

    @Published var showModelConfig = false

    @Published var model: String

    @Published var current = ChatMessage(role: .user, content: "")

    @Published var messages: [ChatMessage]

    @Published var waitingResponse: Bool = false
    @Published var disabledButton: Bool = true

    @Published var errorModel = ErrorModel(showError: false, errorTitle: "", errorMessage: "")

    var work: Task<Void, Never>?

    @MainActor
    func send() {
        work = Task {
            do {
                self.errorModel.showError = false
                waitingResponse = true

                if messages.isEmpty {
                    messages.append(.globalSystem)
                }

                if !current.content.isEmpty {
                    self.messages.append(current)
                }

                current = .init(role: .user, content: "")

                let filterdModel: String = {
                    if tags.models.contains(where: { $0.name == model }) {
                        return model
                    } else {
                        return tags.models.first?.name ?? ""
                    }
                }()

                if filterdModel.isEmpty {
                    waitingResponse = false
                    errorModel = noModelsError(error: nil)
                }

                let chatHistory = ChatModel(
                    model: filterdModel,
                    messages: messages
                )

                let endpoint = "\(host):\(port)" + "/api/chat"

                guard let url = URL(string: endpoint) else {
                    throw NetError.invalidURL(error: nil)
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                request.httpBody = try encoder.encode(chatHistory)

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

                self.messages.append(.init(role: .assistant, content: ""))
                for try await line in data.lines {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let data = line.data(using: .utf8)!
                    let decoded = try! decoder.decode(ResponseModel.self, from: data)
                    self.messages[self.messages.index(before: self.messages.endIndex)].content +=
                        decoded.message.content
                }

                waitingResponse = false
                current.content = ""
                if let currentChat {
                    currentChat.messages = messages
                    currentChat.model = filterdModel
                    CoreDataStack.shared.saveContext()
                } else {
                    let newChat = SingleChat.createNewSingleChat(messages: messages, model: model)
                    newChat.model = filterdModel
                    CoreDataStack.shared.saveContext()
                    currentChat = newChat
                }
                model = filterdModel
            } catch let NetError.invalidURL(error) {
                errorModel = invalidURLError(error: error)
            } catch let NetError.invalidData(error) {
                errorModel = invalidDataError(error: error)
            } catch let NetError.invalidResponse(error) {
                errorModel = invalidResponseError(error: error)
            } catch let NetError.unreachable(error) {
                errorModel = unreachableError(error: error)
            } catch let error as URLError where error.code == .cancelled {
                waitingResponse = false
                current.content = ""
            } catch {
                self.errorModel = genericError(error: error)
            }
        }
    }

    func resetChat() {
        waitingResponse = false
        work?.cancel()
        messages = [.globalSystem]
        saveDataToDatabase()
    }

    @MainActor
    func resendUntil(_ message: ChatMessage) {
        guard let idx = messages.firstIndex(where: { $0.id == message.id }) else { return }
        waitingResponse = false
        work?.cancel()
        if idx < messages.endIndex {
            messages = Array(messages[...idx])
        }
        current = .init(role: .user, content: "")
        if messages.last?.role == .user {
            send()
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
            model = chat.model
            currentChat = chat
        } else {
            messages = [.globalSystem]
            currentChat = nil
        }
    }

    func newChat() {
        let newChat = SingleChat.createNewSingleChat(
            messages: [],
            model: tags.models.first?.name ?? ""
        )
        CoreDataStack.shared.saveContext()
        loadChat(newChat)
    }
}
