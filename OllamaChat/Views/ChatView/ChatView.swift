//
//  ChatView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Hue
import SwiftUI
import SwiftUIIntrospect

struct ChatView: View {
    let fontSize: CGFloat = 15

    @State private var showingErrorPopover: Bool = false

    @ObservedObject var viewModel = ChatViewModel.shared

    @FocusState var promptFieldIsFocused: Bool

    @Namespace var bottomID

    var body: some View {
        ZStack {
            messagesList
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 600, idealHeight: 800)
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            self.getTags()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    Picker("Model:", selection: $viewModel.model) {
                        ForEach(viewModel.tags.models, id: \.self) { model in
                            Text(model.modelInfo.model).tag(model.name)
                        }
                    }
                }
                if viewModel.errorModel.showError {
                    Button {
                        self.showingErrorPopover.toggle()
                    } label: {
                        Label("Error", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    .popover(isPresented: self.$showingErrorPopover) {
                        VStack(alignment: .leading) {
                            Text(viewModel.errorModel.errorTitle)
                                .font(.title2)
                                .textSelection(.enabled)
                            Text(viewModel.errorModel.errorMessage)
                                .textSelection(.enabled)
                        }
                        .padding()
                    }
                } else {
                    Text("Server:")
                    Label("Connected", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                }
                Button {
                    self.getTags()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSystemConfig) {
            SystemEditorView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showModelConfig) {
            ManageModelsView()
        }
        .sheet(isPresented: $viewModel.showEditingMessage) {
            MessageEditorView(viewModel: viewModel)
        }
    }

    func actionButton(_ sfName: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: sfName)
                .frame(width: 20, height: 20, alignment: .center)
                .frame(width: 40, height: 32)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue))
        }
        .buttonStyle(.plain)
    }

    func getTags() {
        Task {
            do {
                viewModel.disabledButton = false
                viewModel.waitingResponse = false
                viewModel.errorModel.showError = false
                viewModel.tags = try await getLocalModels(
                    host: "\(viewModel.host):\(viewModel.port)",
                    timeoutRequest: viewModel.timeoutRequest,
                    timeoutResource: viewModel.timeoutResource
                )
                if viewModel.tags.models.count > 0 {
                    viewModel.model = viewModel.tags.models[0].name
                } else {
                    viewModel.model = ""
                    viewModel.errorModel = noModelsError(error: nil)
                }
            } catch let NetError.invalidURL(error) {
                viewModel.errorModel = invalidURLError(error: error)
            } catch let NetError.invalidData(error) {
                viewModel.errorModel = invalidTagsDataError(error: error)
            } catch let NetError.invalidResponse(error) {
                viewModel.errorModel = invalidResponseError(error: error)
            } catch let NetError.unreachable(error) {
                viewModel.errorModel = unreachableError(error: error)
            } catch {
                viewModel.errorModel = genericError(error: error)
            }
        }
    }
}

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
    
    @Published var textToTranslate: String = ""

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

                let chatHistory = ChatModel(
                    model: model,
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
                    CoreDataStack.shared.saveContext()
                } else {
                    let newChat = SingleChat.createNewSingleChat(messages: messages, model: model)
                    CoreDataStack.shared.saveContext()
                    currentChat = newChat
                }
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
