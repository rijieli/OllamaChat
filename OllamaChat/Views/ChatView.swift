//
//  ChatView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import SwiftUI
import SwiftUIIntrospect
import Hue

struct ChatView: View {
    let fontSize: CGFloat = 15
    
    @State private var tags: ModelGroup?
    @State private var showingErrorPopover: Bool = false
    
    @ObservedObject var viewModel = ChatViewModel.shared
    
    @FocusState private var promptFieldIsFocused: Bool
    
    @Namespace var bottomID
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text("This is the start of your chat")
                        .foregroundStyle(.secondary)
                        .padding()
                    let messages = viewModel.messages.filter { $0.role != .system }
                    ForEach(messages) { message in
                        let isUser = message.role == .user
                        ChatBubble(direction: isUser ? .right : .left, floatingButtonsAlignment: .bottomTrailing) {
                            MarkdownTextView(message: message.content)
                                .foregroundStyle(isUser ? Color.white : .black)
                                .padding([.leading, .trailing], 8)
                                .padding([.top, .bottom], 8)
                                .textSelection(.enabled)
                                .background(isUser ? Color.blue : Color(hex: "#EBEBEB"))
                        } buttons: {
                            HStack(spacing: 4) {
                                if isUser {
                                    bubbleButton("arrow.clockwise.circle.fill") {
                                        viewModel.resendUntil(message)
                                    }
                                }
                                bubbleButton("pencil.circle.fill") {
                                    viewModel.editMessage(message)
                                }
                                bubbleButton("doc.on.doc.fill") {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents() // Clears the pasteboard before writing
                                    pasteboard.setString(message.content, forType: .string)
                                }
                            }
                            .frame(height: 24)
                            .frame(minWidth: 36)
                            .padding(.horizontal, 3)
                            .background {
                                Capsule().fill(.background)
                            }
                            .overlay {
                                Capsule().strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                            }
                            .offset(x: -4, y: -4)
                        }
                    }
                    
                    Color.clear
                        .maxWidth()
                        .frame(height: 40)
                        .id(bottomID)
                    
                }
                .maxFrame()
                //.defaultScrollAnchor(.bottom)
                .overlay(alignment: .bottom) {
                    HStack {
                        if viewModel.waitingResponse {
                            actionButton("stop.fill") {
                                viewModel.work?.cancel()
                            }
                            .transition(.opacity)
                        }
                        
                        actionButton("gearshape.fill") {
                            viewModel.showSystemConfig = true
                        }
                        
                        actionButton("trash.fill") {
                            viewModel.resetChat()
                        }
                    }
                    .frame(height: 40)
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(.smooth, value: viewModel.waitingResponse)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.messages) { _ in
                    proxy.scrollTo(bottomID)
                }
            }
            
            ZStack {
                TextEditor(text: $viewModel.current.content)
                    .disableAutoQuotes()
                    .font(.body)
                    .onSubmit {
                        !viewModel.disabledButton ? viewModel.send() : nil
                    }
                    .disabled(viewModel.waitingResponse)
                    .focused($promptFieldIsFocused)
                    .onChange(of: viewModel.current.content) { _ in
                        viewModel.disabledButton = viewModel.current.content.isEmpty
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .opacity(viewModel.waitingResponse ? 0 : 1)
                    .overlay {
                        Button {
                            viewModel.send()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .frame(width: 20, height: 20, alignment: .center)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(.blue)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .opacity(viewModel.waitingResponse ? 0 : 1)
                        .padding(.trailing, 12)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .animation(.default, value: viewModel.waitingResponse)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .maxFrame()
            .frame(height: 160)
            
        }
        .frame(minWidth: 400, idealWidth: 700, minHeight: 600, idealHeight: 800)
        .background(Color(NSColor.controlBackgroundColor))
        .task {
            self.getTags()
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic){
                HStack {
                    Picker("Model:", selection: $viewModel.model) {
                        ForEach(tags?.models ?? [], id: \.self) { model in
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
                self.tags = try await getLocalModels(host: "\(viewModel.host):\(viewModel.port)", timeoutRequest: viewModel.timeoutRequest, timeoutResource: viewModel.timeoutResource)
                if(self.tags != nil){
                    if(self.tags!.models.count > 0){
                        viewModel.model = self.tags!.models[0].name
                    }else{
                        viewModel.model = ""
                        viewModel.errorModel = noModelsError(error: nil)
                    }
                }else{
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
    
    func bubbleButton(_ systemName: String, action: VoidClosureOptionl) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .font(.system(size: 16, weight: .bold))
                .padding(4)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                
                print("Sending request \(chatHistory)")
                
                let data: URLSession.AsyncBytes
                let response: URLResponse
                
                do {
                    let sessionConfig = URLSessionConfiguration.default
                    sessionConfig.timeoutIntervalForRequest = Double(timeoutRequest) ?? 60
                    sessionConfig.timeoutIntervalForResource = Double(timeoutResource) ?? 604800
                    (data, response) = try await URLSession(configuration: sessionConfig).bytes(for: request)
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
                    self.messages[self.messages.index(before: self.messages.endIndex)].content += decoded.message.content
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
        guard let idx = messages.firstIndex(where: { $0.id == message.id}) else { return }
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
        guard let idx = messages.firstIndex(where: { $0.id == message.id}) else { return }
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
}
