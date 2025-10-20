//
//  WebAPISettingsVIew.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/2.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct WebAPISettingsView: View {
    @StateObject private var modelManager = APIManager.shared
    @StateObject private var modelRegistry = ModelRegistry.shared

    @State private var isAddingNewAPI = false
    @State private var editingCompletion: ChatCompletion?
    @State private var apiToDelete: ChatCompletion?
    @State private var showDeleteConfirmation = false

    @State private var newCompletionName = ""
    @State private var newCompletionEndpoint = ""
    @State private var newCompletionApiKey = ""
    @State private var selectedProvider: ModelProvider = .openai
    @State private var showProviderSelector = false

    @State private var selectedModel: ModelRegistry.AIModel?
    @State private var manualModelName = ""

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader("Web API Connections")
                .maxWidth(alignment: .leading)

            if modelManager.completions.isEmpty {
                Text("No API connections configured.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                List {
                    ForEach(modelManager.completions, id: \.name) { completion in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(completion.name)
                                        .font(.headline)
                                    Spacer()
                                    Text(completion.provider.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                        .foregroundStyle(.blue)
                                }
                                Text(completion.selectedModel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(completion.endpoint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                prepareForEditing(completion)
                            }) {
                                Image(systemName: "pencil")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                apiToDelete = completion
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(height: 100)
                .modifier(BorderDecoratedStyleModifier(paddingV: 8))
            }

            Menu {
                ForEach(modelManager.getAvailableProviders(), id: \.self) { provider in
                    Button(action: {
                        selectedProvider = provider
                        resetNewCompletionFields()
                        isAddingNewAPI = true
                    }) {
                        HStack {
                            Text(provider.displayName)
                            if provider == .ollama {
                                Image(systemName: "server.rack")
                            } else {
                                Image(systemName: "cloud")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add New API Connection")
                }
            }
            .padding(.top, 8)

            if isAddingNewAPI || editingCompletion != nil {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(editingCompletion != nil ? "Edit API Connection" : "New API Connection")
                            .font(.headline)
                        Spacer()
                        if isAddingNewAPI {
                            Text(selectedProvider.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundStyle(.blue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Name", text: $newCompletionName)

                        if isAddingNewAPI || editingCompletion?.provider == .ollama {
                            TextField("Endpoint URL", text: $newCompletionEndpoint)
                                .placeholder(when: newCompletionEndpoint.isEmpty) {
                                    Text("http://127.0.0.1:11434").foregroundStyle(.secondary)
                                }
                        } else {
                            // Show endpoint for cloud providers (optional)
                            TextField("Endpoint URL (optional)", text: $newCompletionEndpoint)
                                .placeholder(when: newCompletionEndpoint.isEmpty) {
                                    Text("Leave empty to use default endpoint").foregroundStyle(.secondary)
                                }
                        }

                        if (isAddingNewAPI && selectedProvider.requiresAPIKey) ||
                           (editingCompletion != nil && editingCompletion!.provider.requiresAPIKey) {
                            SecureField("API Key", text: $newCompletionApiKey)
                        }

                        // Model Selection
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model")
                                .font(.caption)
                                .fontWeight(.medium)

                            if isAddingNewAPI || editingCompletion != nil {
                                let currentCompletion = isAddingNewAPI ?
                                    ChatCompletion(
                                        provider: selectedProvider,
                                        name: newCompletionName,
                                        endpoint: newCompletionEndpoint,
                                        apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                                        selectedModel: selectedModel?.id ?? manualModelName
                                    ) :
                                    editingCompletion!

                                if modelRegistry.isLoading(for: currentCompletion) {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Fetching models...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(height: 32)
                                } else if let error = modelRegistry.getError(for: currentCompletion) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle")
                                                .foregroundStyle(.orange)
                                            Text("Error fetching models")
                                                .font(.caption)
                                                .foregroundStyle(.orange)
                                            Spacer()
                                            Button("Retry") {
                                                Task {
                                                    await modelRegistry.fetchModels(for: currentCompletion)
                                                }
                                            }
                                            .font(.caption)
                                        }
                                        Text(error.localizedDescription)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(height: 32)
                                } else {
                                    let availableModels = modelRegistry.getModels(for: currentCompletion)
                                    if !availableModels.isEmpty {
                                        Menu {
                                            ForEach(availableModels) { model in
                                                Button(action: {
                                                    selectedModel = model
                                                    manualModelName = ""
                                                }) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(model.displayName)
                                                                .font(.caption)
                                                            if let contextLength = model.contextLength {
                                                                Text("Context: \(contextLength.formatted()) tokens")
                                                                    .font(.caption2)
                                                                    .foregroundStyle(.secondary)
                                                            }
                                                        }
                                                        Spacer()
                                                        if let selectedModel = selectedModel, selectedModel.id == model.id {
                                                            Image(systemName: "checkmark")
                                                                .foregroundStyle(.blue)
                                                        }
                                                    }
                                                }
                                            }
                                            Button("Manual Entry") {
                                                selectedModel = nil
                                                manualModelName = ""
                                            }
                                        } label: {
                                            HStack {
                                                Text(selectedModel?.displayName ?? (manualModelName.isEmpty ? "Select a model" : manualModelName))
                                                    .foregroundStyle(selectedModel != nil || !manualModelName.isEmpty ? .primary : .secondary)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .frame(height: 32)
                                            .padding(.horizontal, 8)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(6)
                                        }
                                    } else {
                                        VStack(alignment: .leading, spacing: 4) {
                                            TextField("Model name", text: $manualModelName)
                                                .placeholder(when: manualModelName.isEmpty) {
                                                    Text("e.g., gpt-4, claude-3-sonnet").foregroundStyle(.secondary)
                                                }

                                            HStack {
                                                Button("Fetch Models") {
                                                    Task {
                                                        await modelRegistry.fetchModels(for: currentCompletion)
                                                    }
                                                }
                                                .font(.caption)
                                                .disabled(newCompletionApiKey.isEmpty && selectedProvider.requiresAPIKey)

                                                Spacer()

                                                Text("Enter model name manually or fetch from API")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Button("Cancel") {
                            isAddingNewAPI = false
                            editingCompletion = nil
                        }

                        Spacer()

                        Button(editingCompletion != nil ? "Update" : "Create") {
                            if editingCompletion != nil {
                                updateExistingCompletion()
                            } else {
                                createNewCompletion()
                            }
                        }
                        .disabled(
                            newCompletionName.isEmpty ||
                            (selectedModel == nil && manualModelName.isEmpty) ||
                            (isAddingNewAPI && selectedProvider != .ollama && selectedProvider.requiresAPIKey && newCompletionApiKey.isEmpty) ||
                            (editingCompletion != nil && editingCompletion!.provider.requiresAPIKey && newCompletionApiKey.isEmpty) ||
                            (isAddingNewAPI && selectedProvider == .ollama && newCompletionEndpoint.isEmpty) ||
                            (editingCompletion != nil && editingCompletion!.provider == .ollama && newCompletionEndpoint.isEmpty)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .maxWidth()
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete API Connection"),
                message: Text("Are you sure you want to delete '\(apiToDelete?.name ?? "")'?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let apiToDelete = apiToDelete {
                        deleteCompletion(apiToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func createNewCompletion() {
        do {
            // Validate URL for providers that require it
            if selectedProvider == .ollama {
                if !isValidURL(newCompletionEndpoint) {
                    errorMessage = "Please enter a valid URL"
                    showError = true
                    return
                }
            }

            let modelName = selectedModel?.id ?? manualModelName

            try modelManager.createCompletion(
                provider: selectedProvider,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty ? getDefaultEndpointForProvider(selectedProvider) : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                selectedModel: modelName
            )

            isAddingNewAPI = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func updateExistingCompletion() {
        guard
            let index = modelManager.completions.firstIndex(where: {
                $0.name == editingCompletion?.name
            })
        else {
            return
        }

        do {
            // Validate URL for providers that require it
            if editingCompletion!.provider == .ollama {
                if !isValidURL(newCompletionEndpoint) {
                    errorMessage = "Please enter a valid URL"
                    showError = true
                    return
                }
            }

            let modelName = selectedModel?.id ?? manualModelName

            modelManager.updateCompletion(
                at: index,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty ? getDefaultEndpointForProvider(editingCompletion!.provider) : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                selectedModel: modelName
            )

            editingCompletion = nil
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deleteCompletion(_ completion: ChatCompletion) {
        modelManager.deleteCompletion(withName: completion.name)
        apiToDelete = nil
    }

    private func prepareForEditing(_ completion: ChatCompletion) {
        newCompletionName = completion.name
        newCompletionEndpoint = completion.endpoint
        newCompletionApiKey = completion.apiKey ?? ""
        selectedProvider = completion.provider
        editingCompletion = completion

        // Extract model from configuration
        selectedModel = nil
        manualModelName = completion.selectedModel

        // Try to find matching model in registry
        let availableModels = modelRegistry.getModels(for: completion)
        if let matchingModel = availableModels.first(where: { $0.id == completion.selectedModel || $0.name == completion.selectedModel }) {
            selectedModel = matchingModel
            manualModelName = ""
        }

        // Trigger model fetching if needed
        Task {
            await modelRegistry.fetchModels(for: completion)
        }
    }

    private func resetNewCompletionFields() {
        newCompletionName = ""
        newCompletionEndpoint = ""
        newCompletionApiKey = ""
        selectedModel = nil
        manualModelName = ""
        selectedProvider = .openai
    }

    private func getDefaultEndpointForProvider(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "http://127.0.0.1:11434"
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .gemini: return "https://generativelanguage.googleapis.com"
        case .openrouter: return "https://openrouter.ai/api/v1"
        }
    }

    private func isValidURL(_ urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return NSApplication.shared.canOpenURL(url)
        }
        return false
    }

    private func isValidJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }
}