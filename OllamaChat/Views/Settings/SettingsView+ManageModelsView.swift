//
//  ManageModelsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import SwiftUI

#if os(macOS)
struct ManageModelsView: View {
    
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
        ScrollView {
            configContent
        }
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
