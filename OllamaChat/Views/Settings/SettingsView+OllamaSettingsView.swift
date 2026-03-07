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
                    case .chatOptions:
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsSectionHeader(
                                "New Chat Defaults",
                                subtitle: "Used only when a new chat is created."
                            )
                            ModelEditingView(chatOptions: $viewModel.defaultChatOptions)
                        }
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

            DefaultModelPickerView()

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

private struct DefaultModelPickerView: View {
    @ObservedObject private var apiManager = APIManager.shared
    @ObservedObject private var chatViewModel = ChatViewModel.shared

    private var defaultModelBinding: Binding<String> {
        Binding(
            get: { apiManager.selectedModel },
            set: { apiManager.updateSelectedModel($0) }
        )
    }

    private var availableModelNames: [String] {
        let liveModelNames = chatViewModel.tags.models.map(\.name)
        let modelNames = liveModelNames.isEmpty ? apiManager.configuration.models : liveModelNames
        guard !apiManager.selectedModel.isEmpty,
            !modelNames.contains(apiManager.selectedModel)
        else {
            return modelNames
        }

        return [apiManager.selectedModel] + modelNames
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader(
                "New Chat Model",
                subtitle: "Changing the model inside a chat does not change this default."
            )

            if availableModelNames.isEmpty {
                Text("Refresh the model list to choose a default model for new chats.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Default Model:") {
                    Picker("Default Model:", selection: defaultModelBinding) {
                        ForEach(availableModelNames, id: \.self) { modelName in
                            Text(label(for: modelName))
                                .tag(modelName)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .labeledContentStyle(.settings)
            }
        }
    }

    private func label(for modelName: String) -> String {
        let knownModelNames = Set(chatViewModel.tags.models.map(\.name))
            .union(apiManager.configuration.models)
        guard !knownModelNames.contains(modelName) else {
            return modelName
        }

        return "\(modelName) (Unavailable)"
    }
}
#endif

private let helperText: LocalizedStringKey = """
    If you are using a web URL as the host, you can try removing the port. If you are running Ollama locally, try using http://127.0.0.1 and set the port to 11434.
    """
