//
//  GeneralSettingsView.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/23.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

#if os(macOS)
import SwiftUI
import AVFoundation

extension SettingsView {
    struct OllamaSettingsView: View {
        @ObservedObject var chatViewModel = ChatViewModel.shared
        @ObservedObject var viewModel = SettingsViewModel.shared
        
        var body: some View {
            VStack(spacing: 0) {
                // Segmented control for Ollama sub-tabs
                Picker("", selection: $viewModel.selectedOllamaSubTab) {
                    ForEach(OllamaSubTab.allCases) { subTab in
                        Text(subTab.title).tag(subTab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 16)
                .maxWidth()
                .background {
                    LinearGradient(
                        colors: [
                            .white,
                            .white,
                            .white.opacity(0.8),
                            .white.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .zIndex(1)
                
                ScrollView(.vertical, showsIndicators: false) {
                    // Content based on selected sub-tab
                    switch viewModel.selectedOllamaSubTab {
                    case .general:
                        ModelConfigView()
                            .padding(.horizontal, 24)
                    case .models:
                        ManageModelsView()
                            .padding(.horizontal, 24)
                    case .chatOptions:
                        ModelEditingView(viewModel: chatViewModel)
                            .padding(.horizontal, 24)
                    }
                }
                .ifScrollClipDisabled(true)
            }
        }
    }
}

private struct ModelConfigView: View {
    
    @ObservedObject var chatViewModel = ChatViewModel.shared
    
    var host: String { chatViewModel.host }
    var port: String { chatViewModel.port }
    var timeoutRequest: String { chatViewModel.timeoutRequest }
    var timeoutResource: String { chatViewModel.timeoutResource }
    
    @State private var isTestingConnection = false
    @State private var testResult: (success: Bool, message: String)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader("Ollama Service")
            VStack {
                LabeledContent("Host:") {
                    TextField("Host:", text: $chatViewModel.host)
                }
                LabeledContent("Port(optional):") {
                    TextField("Port(optional):", text: $chatViewModel.port)
                        .onChange(of: port) { _ in
                            let filtered = port.filter { "0123456789".contains($0) }
                            if filtered != port {
                                chatViewModel.port = filtered
                            }
                        }
                }
            }
            
            LabeledContent("Request Timeout (Default 60s):") {
                TextField(
                    "Request Timeout (Default 60s):",
                    text: $chatViewModel.timeoutRequest
                )
                .onChange(of: timeoutRequest) { _ in
                    let filtered = timeoutRequest.filter { "0123456789".contains($0) }
                    if filtered != timeoutRequest {
                        chatViewModel.timeoutRequest = filtered
                    }
                }
            }
            .labeledContentStyle(.settings)
            
            HStack(spacing: 8) {
                Button(action: testConnection) {
                    Text("Test Connection")
                }
                .disabled(isTestingConnection)
                
                if isTestingConnection {
                    ProgressView()
                        .controlSize(.small)
                } else if let result = testResult {
                    HStack(spacing: 4) {
                        Image(
                            systemName: result.success
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(result.success ? .green : .red)
                        Text(result.message)
                            .lineLimit(1)
                            .foregroundColor(result.success ? .green : .red)
                    }
                }
            }
            
            if let result = testResult, result.success == false {
                Text(helperText)
                    .lineLimit(3, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .maxWidth(alignment: .leading)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            }
        }
        .maxWidth()
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                _ = try await fetchOllamaModels(timeout: 5)
                DispatchQueue.main.async {
                    self.testResult = (
                        true, "Connected: \(APIEndPoint)"
                    )
                    self.isTestingConnection = false
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.testResult = (false, error.localizedDescription)
                    self.isTestingConnection = false
                }
            }
        }
    }
}
#endif

private let helperText: LocalizedStringKey = """
    If you are using a web URL as the host, you can try removing the port. If you are running Ollama locally, try using http://127.0.0.1 and set the port to 11434.
    """

#if os(macOS)
private struct ManageModelsView: View {
    
    @ObservedObject var chatViewModel = ChatViewModel.shared
    
    @State private var errorModel: ErrorModel = ErrorModel(
        showError: false,
        errorTitle: "",
        errorMessage: ""
    )
    @State private var modelToDownlad: String = ""
    @State private var showProgress: Bool = false
    @State private var showingErrorPopover: Bool = false
    @State private var totalSize: Double = 0
    @State private var completedSoFar: Double = 0
    
    var tags: OllamaModelGroup {
        chatViewModel.tags
    }
    
    var host: String { chatViewModel.host }
    var port: String { chatViewModel.port }
    var timeoutRequest: String { chatViewModel.timeoutRequest }
    var timeoutResource: String { chatViewModel.timeoutResource }
    
    @State private var modelToDelete: OllamaLanguageModel?
    @State private var showModelDeletionAlert = false
    
    var body: some View {
        configContent
    }
    
    var configContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SettingsSectionHeader("Local Models:")
                Spacer(minLength: 0)
                HStack {
                    if errorModel.showError {
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
                        Label("Connected", systemImage: "circle.fill")
                            .foregroundStyle(.green)
                            .fixedWidth()
                    }
                    Button {
                        getTags()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                }
                .task {
                    getTags()
                }
            }
            
            if tags.models.count == 0 {
                HStack {
                    Label("Error", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(
                        "No models downloaded locally. Add a model by typing the name in the field at the bottom of the page."
                    )
                }
            }
            List(tags.models, id: \.self) { model in
                HStack(spacing: 0) {
                    Text(model.name)
                        .padding(.trailing, 10)
                    Spacer()
                    Text(model.fileSize)
                        .padding(.trailing, 10)
                    Button {
                        modelToDelete = model
                        showModelDeletionAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                }
            }
            .listStyle(.plain)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(height: 250)
            .modifier(BorderDecoratedStyleModifier(paddingV: 8))
            .padding(.bottom, 8)
            
            HStack {
                Text("Get Model:")
                    .font(.headline)
                TextField("Model name. e.g. llama3", text: $modelToDownlad)
                    .textFieldStyle(.roundedBorder)
                Button {
                    downloadModel(name: modelToDownlad)
                } label: {
                    Image(systemName: "arrowshape.down.fill")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
            if showProgress {
                HStack {
                    Text("Downloading \(modelToDownlad)")
                    ProgressView(value: completedSoFar, total: totalSize)
                    Text(
                        "\(Int(completedSoFar / 1024 / 1024 ))/ \(Int(totalSize / 1024 / 1024)) MB"
                    )
                }
            }
            Text("Find more models: [Models](https://ollama.com/library)")
        }
        .maxWidth()
        .alert("Are you sure you want to delete the model?", isPresented: $showModelDeletionAlert) {
            Button("Cancel", role: .cancel) {
                modelToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let modelToDelete = modelToDelete {
                    removeModel(name: modelToDelete.name)
                }
                modelToDelete = nil
            }
        }
    }
    
    func getTags() {
        Task {
            do {
                errorModel.showError = false
                _ = try await fetchOllamaModels()
                if tags.models.count == 0 {
                    errorModel = noModelsError(error: nil)
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func downloadModel(name: String) {
        Task {
            do {
                showProgress = true
                
                let endpoint = APIEndPoint + "pull"
                
                guard let url = URL(string: endpoint) else {
                    throw NetError.invalidURL(error: nil)
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = "{\"name\":\"\(name)\"}".data(using: String.Encoding.utf8)!
                
                let data: URLSession.AsyncBytes
                let response: URLResponse
                
                do {
                    (data, response) = try await URLSession.shared.bytes(for: request)
                } catch {
                    throw NetError.unreachable(error: error)
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode == 200
                else {
                    throw NetError.invalidResponse(error: nil)
                }
                
                for try await line in data.lines {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let data = line.data(using: .utf8)!
                    let decoded = try decoder.decode(DownloadResponseModel.self, from: data)
                    self.completedSoFar = decoded.completed ?? 0
                    self.totalSize = decoded.total ?? 100
                }
                
                showProgress = false
                getTags()
            } catch {
                handleError(error)
            }
        }
    }
    
    func removeModel(name: String) {
        Task {
            do {
                try await deleteModel(name: name)
                getTags()
            } catch {
                handleError(error)
            }
        }
    }
    
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
}

#endif
