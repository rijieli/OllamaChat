//
//  ChatView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import MarkdownUI
import SwiftUI
import SwiftUIIntrospect

struct ChatView: View {
    let fontSize: CGFloat = 15
    
    @State private var tags: ModelGroup?
    @State private var showingErrorPopover: Bool = false
    
    @ObservedObject var viewModel = ViewModel()
    
    @FocusState private var promptFieldIsFocused: Bool
    
    @Namespace var bottomID
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text("This is the start of your chat")
                        .foregroundStyle(.secondary)
                        .padding()
                    ForEach(Array(viewModel.sentPrompt.enumerated()), id: \.offset) { idx, sent in
                        ChatBubble(direction: .right, onTapFloatingButton: {
                            viewModel.resendUntil(idx)
                        }) {
                            Markdown {
                                .init(sent.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            .markdownTextStyle{
                                ForegroundColor(Color.white)
                            }
                            .padding([.leading, .trailing], 8)
                            .padding([.top, .bottom], 8)
                            .textSelection(.enabled)
                            .background(Color.blue)
                        }
                        
                        ChatBubble(direction: .left) {
                            Markdown {
                                .init(viewModel.receivedResponse.indices.contains(idx) ?
                                      viewModel.receivedResponse[idx].trimmingCharacters(in: .whitespacesAndNewlines) :
                                        "...")
                            }
                            .markdownTextStyle(\.code) {
                                FontFamilyVariant(.monospaced)
                                BackgroundColor(.white.opacity(0.25))
                            }
                            .markdownBlockStyle(\.codeBlock) { configuration in
                                configuration.label
                                    .padding()
                                    .markdownTextStyle {
                                        FontFamilyVariant(.monospaced)
                                    }
                                    .background(Color.white.opacity(0.25))
                            }
                            .padding([.leading, .trailing], 8)
                            .padding([.top, .bottom], 8)
                            .textSelection(.enabled)
                            .foregroundStyle(Color.secondary)
                            .background(Color(NSColor.secondarySystemFill))
                        }
                    }
                    
                    Color.clear
                        .maxWidth()
                        .frame(height: 40)
                        .id(bottomID)
                    
                }
                .maxFrame()
                .defaultScrollAnchor(.bottom)
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
                .onChange(of: viewModel.receivedResponse) { _, _ in
                    proxy.scrollTo(bottomID)
                }
            }
            
            
            VStack {
                ZStack {
                    TextEditor(text: $viewModel.current.prompt)
                        .introspect(.textEditor, on: .macOS(.v14, .v13)) { nsTextView in
                            nsTextView.isAutomaticQuoteSubstitutionEnabled = false
                            nsTextView.isAutomaticDashSubstitutionEnabled = false
                        }
                        .font(.body)
                        .onSubmit {
                            !viewModel.disabledButton ? viewModel.send() : nil
                        }
                        .disabled(viewModel.waitingResponse)
                        .focused($promptFieldIsFocused)
                        .onChange(of: viewModel.current.prompt) {
                            viewModel.disabledButton = viewModel.current.prompt.isEmpty
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
            }
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
                    Picker("Model:", selection: $viewModel.current.model) {
                        ForEach(self.tags?.models ?? [], id: \.self) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                    Button {
                        viewModel.showModelConfig = true
                    } label: {
                        Label("Manage Models", systemImage: "cube")
                            .fontWeight(.bold)
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
                        viewModel.current.model = self.tags!.models[0].name
                    }else{
                        viewModel.current.model = ""
                        viewModel.errorModel = noModelsError(error: nil)
                    }
                }else{
                    viewModel.current.model = ""
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

#Preview {
    ChatView()
}

extension ChatView {
    
    class ViewModel: ObservableObject {
        
        @AppStorage("host") var host = "http://127.0.0.1"
        @AppStorage("port") var port = "11434"
        @AppStorage("timeoutRequest") var timeoutRequest = "60"
        @AppStorage("timeoutResource") var timeoutResource = "604800"
        
        @Published var showSystemConfig = false
        
        @Published var showModelConfig = false
        
        @Published var current: PromptModel = .init(
            prompt: "",
            model: "",
            system: AppSettings.globalSystem
        )
        
        @Published var receivedResponse: [String] = []
        @Published var sentPrompt: [String] = []
        
        @Published var waitingResponse: Bool = false
        @Published var disabledButton: Bool = true
        
        @Published var errorModel = ErrorModel(showError: false, errorTitle: "", errorMessage: "")
        
        var work: Task<Void, Never>?
        
        @MainActor
        func send() {
            guard !current.prompt.isEmpty else { return }
            work = Task {
                do {
                    self.errorModel.showError = false
                    waitingResponse = true
                    
                    self.sentPrompt.append(current.prompt)
                    
                    var messages = [ChatMessage]()
                    
                    if !current.system.isEmpty {
                        messages.append(ChatMessage(role: "system", content: current.system))
                    }
                    
                    for i in 0 ..< self.sentPrompt.count {
                        messages.append(ChatMessage(role: "user", content: self.sentPrompt[i]))
                        if i < receivedResponse.count {
                            messages.append(ChatMessage(role: "assistant", content: self.receivedResponse[i]))
                        }
                    }
                    
                    self.receivedResponse.append("")
                    
                    let chatHistory = ChatModel(
                        model: current.model,
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
                    
                    for try await line in data.lines {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let data = line.data(using: .utf8)!
                        let decoded = try decoder.decode(ResponseModel.self, from: data)
                        self.receivedResponse[self.receivedResponse.count - 1].append(decoded.message.content)
                    }
                    waitingResponse = false
                    current.prompt = ""
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
                    current.prompt = ""
                } catch {
                    self.errorModel = genericError(error: error)
                }
            }
        }
        
        func resetChat() {
            waitingResponse = false
            work?.cancel()
            sentPrompt = []
            receivedResponse = []
        }
        
        @MainActor
        func resendUntil(_ idx: Int) {
            guard idx <= (sentPrompt.count - 1) else { return }
            let prompt = sentPrompt[idx]
            waitingResponse = false
            work?.cancel()
            sentPrompt = sentPrompt.prefix(idx).map { $0 }
            receivedResponse = receivedResponse.prefix(idx).map { $0 }
            current.prompt = prompt
            send()
        }
    }
    
}
