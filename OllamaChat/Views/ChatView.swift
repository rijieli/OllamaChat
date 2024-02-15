//
//  ChatView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import MarkdownUI
import SwiftUI

struct ChatView: View {
    let fontSize: CGFloat = 15
    
    @State private var sentPrompt: [String] = []
    @State private var receivedResponse: [String] = []
    @State private var tags: tagsParent?
    @State private var disabledButton: Bool = true
    @State private var disabledEditor: Bool = false
    @State private var showingErrorPopover: Bool = false
    @State private var errorModel: ErrorModel = .init(showError: false, errorTitle: "", errorMessage: "")
    
    @ObservedObject var viewModel = ViewModel()
    
    @FocusState private var promptFieldIsFocused: Bool
    
    @AppStorage("host") private var host = "http://127.0.0.1"
    @AppStorage("port") private var port = "11434"
    @AppStorage("timeoutRequest") private var timeoutRequest = "60"
    @AppStorage("timeoutResource") private var timeoutResource = "604800"
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Text("This is the start of your chat")
                    .foregroundStyle(.secondary)
                    .padding()
                ForEach(Array(self.sentPrompt.enumerated()), id: \.offset) { idx, sent in
                    ChatBubble(direction: .right, onTapFloatingButton: {
                        print(idx)
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
                            .init(self.receivedResponse.indices.contains(idx) ?
                                  self.receivedResponse[idx].trimmingCharacters(in: .whitespacesAndNewlines) :
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
            }
            .defaultScrollAnchor(.bottom)
            VStack {
                HStack {
                    actionButton("gearshape.fill") {
                        viewModel.showSystemConfig = true
                    }
                    
                    actionButton("trash.fill") {
                        self.resetChat()
                    }
                }
                .frame(height: 40)
                .padding(.trailing, 12)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                HStack(spacing: 12) {
                    ZStack {
                        TextEditor(text: $viewModel.current.prompt)
                            .font(.body)
                            .onSubmit {
                                !self.disabledButton ? self.send() : nil
                            }
                            .disabled(self.disabledEditor)
                            .focused(self.$promptFieldIsFocused)
                            .onChange(of: viewModel.current.prompt) {
                                self.disabledButton = viewModel.current.prompt.isEmpty
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .opacity(disabledEditor ? 0 : 1)
                            .overlay {
                                Button {
                                    send()
                                } label: {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .frame(width: 40, height: 40)
                                        .foregroundStyle(.blue)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .opacity(self.disabledButton ? 0 : 1)
                                .padding(.trailing, 12)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .animation(.default, value: disabledButton)
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
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
                if self.errorModel.showError {
                    Button {
                        self.showingErrorPopover.toggle()
                    } label: {
                        Label("Error", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                    .popover(isPresented: self.$showingErrorPopover) {
                        VStack(alignment: .leading) {
                            Text(self.errorModel.errorTitle)
                                .font(.title2)
                                .textSelection(.enabled)
                            Text(self.errorModel.errorMessage)
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
                self.disabledButton = false
                self.disabledEditor = false
                self.errorModel.showError = false
                self.tags = try await getLocalModels(host: "\(self.host):\(self.port)", timeoutRequest: self.timeoutRequest, timeoutResource: self.timeoutResource)
                if(self.tags != nil){
                    if(self.tags!.models.count > 0){
                        viewModel.current.model = self.tags!.models[0].name
                    }else{
                        viewModel.current.model = ""
                        self.errorModel = noModelsError(error: nil)
                    }
                }else{
                    viewModel.current.model = ""
                    self.errorModel = noModelsError(error: nil)
                }
            } catch let NetError.invalidURL(error) {
                self.errorModel = invalidURLError(error: error)
            } catch let NetError.invalidData(error) {
                self.errorModel = invalidTagsDataError(error: error)
            } catch let NetError.invalidResponse(error) {
                self.errorModel = invalidResponseError(error: error)
            } catch let NetError.unreachable(error) {
                self.errorModel = unreachableError(error: error)
            } catch {
                self.errorModel = genericError(error: error)
            }
        }
    }
    
    func resetChat() {
        self.sentPrompt = []
        self.receivedResponse = []
    }
    
    func send() {
        Task {
            do {
                self.errorModel.showError = false
                self.disabledEditor = true
                
                self.sentPrompt.append(viewModel.current.prompt)
                
                var messages = [ChatMessage]()
                
                if !viewModel.current.system.isEmpty {
                    messages.append(ChatMessage(role: "system", content: viewModel.current.system))
                }
                
                for i in 0 ..< self.sentPrompt.count {
                    messages.append(ChatMessage(role: "user", content: self.sentPrompt[i]))
                    if i < self.receivedResponse.count {
                        messages.append(ChatMessage(role: "assistant", content: self.receivedResponse[i]))
                    }
                }
                
                self.receivedResponse.append("")
                
                let chatHistory = ChatModel(
                    model: viewModel.current.model,
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
                self.disabledEditor = false
                viewModel.current.prompt = ""
            } catch let NetError.invalidURL(error) {
                errorModel = invalidURLError(error: error)
            } catch let NetError.invalidData(error) {
                errorModel = invalidDataError(error: error)
            } catch let NetError.invalidResponse(error) {
                errorModel = invalidResponseError(error: error)
            } catch let NetError.unreachable(error) {
                errorModel = unreachableError(error: error)
            } catch {
                self.errorModel = genericError(error: error)
            }
        }
    }
}

#Preview {
    ChatView()
}

extension ChatView {
    
    class ViewModel: ObservableObject {
        
        @Published var showSystemConfig = false
        
        @Published var showModelConfig = false
        
        @Published var current: PromptModel = .init(
            prompt: "",
            model: "",
            system: AppSettings.globalSystem
        )
        
    }
    
}
