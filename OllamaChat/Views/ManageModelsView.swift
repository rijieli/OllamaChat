//
//  ManageModelsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import SwiftUI

struct ManageModelsView: View {
    @State private var tags: ModelGroup?
    @State private var errorModel: ErrorModel = ErrorModel(
        showError: false,
        errorTitle: "",
        errorMessage: ""
    )
    @State private var modelName: String = ""
    @State private var toDuplicate: String = ""
    @State private var newName: String = ""
    @State private var showProgress: Bool = false
    @State private var showingErrorPopover: Bool = false
    @State private var totalSize: Double = 0
    @State private var completedSoFar: Double = 0
    @State private var globalSystemPrompt = AppSettings.globalSystem

    @Environment(\.dismiss) var dismiss

    @AppStorage("host") private var host = "http://127.0.0.1"
    @AppStorage("port") private var port = "11434"
    @AppStorage("timeoutRequest") private var timeoutRequest = "60"
    @AppStorage("timeoutResource") private var timeoutResource = "604800"

    var body: some View {
        VStack(alignment: .leading) {
            Text("Local Models:")
                .font(.headline)
            if tags?.models.count == 0 {
                HStack {
                    Label("Error", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text(
                        "No models downloaded locally. Add a model by typing the name in the field at the bottom of the page."
                    )
                }
            }
            List(tags?.models ?? [], id: \.self) { model in
                HStack {
                    Text(model.name)
                        .padding(.trailing, 30.0)
                    Text("\(model.size / 1024.0 / 1024.0 / 1024.0, specifier: "%.3f") GB")
                    Spacer()

                    Button {
                        removeModel(name: model.name)
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 20, height: 20, alignment: .center)
                    }
                }
            }
            .frame(maxHeight: 450)

            //            HStack{
            //                Text("Duplicate Model:")
            //                        .font(.headline)
            //                Picker("Duplicate Model:", selection: $toDuplicate) {
            //                    ForEach(tags?.models ?? [], id: \.self) {model in
            //                        Text(model.name).tag(model.name)
            //                    }
            //                }
            //                TextField("New Name", text: $newName)
            //                    .textFieldStyle(.roundedBorder)
            //                Button{
            //                    duplicateModel(source: toDuplicate, destination: newName)
            //                }label: {
            //                    Image(systemName: "doc.on.doc")
            //                        .frame(width: 20, height: 20, alignment: .center)
            //                }
            //            }

            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Global System Prompt:")
                            .font(.headline)
                        Text("Automatic apply to each chat.")
                            .font(.footnote)
                    }
                    Spacer()
                    Button("Save") {
                        AppSettings.globalSystem = globalSystemPrompt
                    }
                }
                TextEditor(text: $globalSystemPrompt)
                    .disableAutoQuotes()
                    .font(.body)
                    .frame(height: 100)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                    )
            }
            HStack {
                Text("Get Model:")
                    .font(.headline)
                TextField("Model name. e.g. llama3", text: $modelName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    downloadModel(name: modelName)
                } label: {
                    Image(systemName: "arrowshape.down.fill")
                        .frame(width: 20, height: 20, alignment: .center)
                }
            }
            if showProgress {
                HStack {
                    Text("Downloading \(modelName)")
                    ProgressView(value: completedSoFar, total: totalSize)
                    Text(
                        "\(Int(completedSoFar / 1024 / 1024 ))/ \(Int(totalSize / 1024 / 1024)) MB"
                    )
                }
            }
            Text("Find more models: [Models](https://ollama.com/library)")

            Color.black.opacity(0.1)
                .frame(height: 0.5)
                .frame(height: 16)
                .maxWidth()

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

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 600, minHeight: 400, idealHeight: 800)
        .task {
            getTags()
        }
    }
    func getTags() {
        Task {
            do {
                tags = try await getLocalModels(
                    host: "\(self.host):\(self.port)",
                    timeoutRequest: self.timeoutRequest,
                    timeoutResource: self.timeoutResource
                )
                errorModel.showError = false
                if self.tags != nil {
                    if self.tags!.models.count > 0 {
                        toDuplicate = self.tags!.models[0].name
                    } else {
                        toDuplicate = ""
                        errorModel = noModelsError(error: nil)
                    }
                } else {
                    toDuplicate = ""
                    errorModel = noModelsError(error: nil)
                }
            } catch NetError.invalidURL(let error) {
                errorModel = invalidURLError(error: error)
            } catch NetError.invalidData(let error) {
                errorModel = invalidTagsDataError(error: error)
            } catch NetError.invalidResponse(let error) {
                errorModel = invalidResponseError(error: error)
            } catch NetError.unreachable(let error) {
                errorModel = unreachableError(error: error)
            } catch {
                errorModel = genericError(error: error)
            }
        }
    }

    func downloadModel(name: String) {
        Task {
            do {
                showProgress = true

                let endpoint = "\(host):\(port)" + "/api/pull"

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

                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
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
            } catch NetError.invalidURL(let error) {
                errorModel = invalidURLError(error: error)
            } catch NetError.invalidData(let error) {
                errorModel = invalidDataError(error: error)
            } catch NetError.invalidResponse(let error) {
                errorModel = invalidResponseError(error: error)
            } catch NetError.unreachable(let error) {
                errorModel = unreachableError(error: error)
            } catch {
                errorModel = genericError(error: error)
            }
        }
    }

    func removeModel(name: String) {
        Task {
            do {
                try await deleteModel(host: "\(host):\(port)", name: name)
                getTags()
            } catch NetError.invalidURL(let error) {
                errorModel = invalidURLError(error: error)
            } catch NetError.invalidData(let error) {
                errorModel = invalidDataError(error: error)
            } catch NetError.invalidResponse(let error) {
                errorModel = invalidResponseError(error: error)
            } catch NetError.unreachable(let error) {
                errorModel = unreachableError(error: error)
            } catch {
                errorModel = genericError(error: error)
            }
        }
    }

    func duplicateModel(source: String, destination: String) {
        Task {
            do {
                try await copyModel(
                    host: "\(host):\(port)",
                    source: source,
                    destination: destination
                )
                getTags()
            } catch NetError.invalidURL(let error) {
                errorModel = invalidURLError(error: error)
            } catch NetError.invalidData(let error) {
                errorModel = invalidDataError(error: error)
            } catch NetError.invalidResponse(let error) {
                errorModel = invalidResponseError(error: error)
            } catch NetError.unreachable(let error) {
                errorModel = unreachableError(error: error)
            } catch {
                errorModel = genericError(error: error)
            }
        }
    }
}
