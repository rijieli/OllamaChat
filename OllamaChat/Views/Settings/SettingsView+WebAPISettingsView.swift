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

    @State private var isAddingNewAPI = false
    @State private var editingCompletion: ChatCompletion?
    @State private var apiToDelete: ChatCompletion?
    @State private var showDeleteConfirmation = false

    @State private var newCompletionName = ""
    @State private var newCompletionEndpoint = ""
    @State private var newCompletionApiKey = ""
    @State private var newCompletionConfig = ""
    @State private var selectedProvider: ModelProvider = .openai
    @State private var showProviderSelector = false

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
                        } else if editingCompletion?.provider != .custom {
                            // Show endpoint for custom providers only
                            TextField("Endpoint URL (optional)", text: $newCompletionEndpoint)
                        } else {
                            TextField("Endpoint URL", text: $newCompletionEndpoint)
                                .placeholder(when: newCompletionEndpoint.isEmpty) {
                                    Text("https://api.example.com/v1").foregroundStyle(.secondary)
                                }
                        }

                        if (isAddingNewAPI && selectedProvider.requiresAPIKey) ||
                           (editingCompletion != nil && editingCompletion!.provider.requiresAPIKey) {
                            SecureField("API Key", text: $newCompletionApiKey)
                        }

                        if (isAddingNewAPI && selectedProvider != .ollama) ||
                           (editingCompletion != nil && editingCompletion!.provider != .ollama) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Configuration (JSON)")
                                    .font(.caption)
                                TextEditor(text: $newCompletionConfig)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(height: 100)
                                    .border(Color.gray.opacity(0.2))

                                if isAddingNewAPI {
                                    Text(getDefaultConfigForProvider(selectedProvider))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
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
                            (isAddingNewAPI && selectedProvider != .ollama && selectedProvider.requiresAPIKey && newCompletionApiKey.isEmpty) ||
                            (editingCompletion != nil && editingCompletion!.provider.requiresAPIKey && newCompletionApiKey.isEmpty) ||
                            (isAddingNewAPI && selectedProvider == .custom && newCompletionEndpoint.isEmpty) ||
                            (editingCompletion != nil && editingCompletion!.provider == .custom && newCompletionEndpoint.isEmpty)
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
            if selectedProvider == .ollama || selectedProvider == .custom {
                if !isValidURL(newCompletionEndpoint) {
                    errorMessage = "Please enter a valid URL"
                    showError = true
                    return
                }
            }

            // Validate JSON if provided
            if !newCompletionConfig.isEmpty {
                if !isValidJSON(newCompletionConfig) {
                    errorMessage = "Configuration is not valid JSON"
                    showError = true
                    return
                }
            }

            try modelManager.createCompletion(
                provider: selectedProvider,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty ? getDefaultEndpointForProvider(selectedProvider) : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                configJSON: newCompletionConfig.isEmpty ? getDefaultConfigForProvider(selectedProvider) : newCompletionConfig
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
            }),
            let completion = editingCompletion
        else {
            return
        }

        do {
            // Validate URL for providers that require it
            if completion.provider == .ollama || completion.provider == .custom {
                if !isValidURL(newCompletionEndpoint) {
                    errorMessage = "Please enter a valid URL"
                    showError = true
                    return
                }
            }

            // Validate JSON if provided
            if !newCompletionConfig.isEmpty {
                if !isValidJSON(newCompletionConfig) {
                    errorMessage = "Configuration is not valid JSON"
                    showError = true
                    return
                }
            }

            modelManager.updateCompletion(
                at: index,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty ? getDefaultEndpointForProvider(completion.provider) : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                configJSON: newCompletionConfig.isEmpty ? getDefaultConfigForProvider(completion.provider) : newCompletionConfig
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
        newCompletionConfig = completion.configJSONRaw ?? ""
        selectedProvider = completion.provider
        editingCompletion = completion
    }

    private func resetNewCompletionFields() {
        newCompletionName = ""
        newCompletionEndpoint = ""
        newCompletionApiKey = ""
        newCompletionConfig = ""
        selectedProvider = .openai
    }

    private func getDefaultEndpointForProvider(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "http://127.0.0.1:11434"
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .gemini: return "https://generativelanguage.googleapis.com"
        case .deepseek: return "https://api.deepseek.com"
        case .groq: return "https://api.groq.com/openai/v1"
        case .togetherai: return "https://api.together.xyz/v1"
        case .custom: return ""
        }
    }

    private func getDefaultConfigForProvider(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return ""
        case .openai: return """
        {
            "model": "gpt-3.5-turbo",
            "useProxy": true
        }
        """
        case .anthropic: return """
        {
            "model": "claude-3-sonnet-20240229",
            "useProxy": true
        }
        """
        case .gemini: return """
        {
            "model": "gemini-pro",
            "useProxy": true
        }
        """
        case .deepseek: return """
        {
            "model": "deepseek-chat",
            "useProxy": true
        }
        """
        case .groq: return """
        {
            "model": "llama3-8b-8192",
            "useProxy": true
        }
        """
        case .togetherai: return """
        {
            "model": "meta-llama/Llama-3-8b-chat-hf",
            "useProxy": true
        }
        """
        case .custom: return """
        {
            "model": "your-model-name",
            "useProxy": false
        }
        """
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
