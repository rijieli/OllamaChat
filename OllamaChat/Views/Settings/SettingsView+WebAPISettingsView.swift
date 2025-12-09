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
    
    @State private var selectedModel: ModelRegistry.AIModel?
    @State private var manualModelName = ""
    
    @State private var errorMessage: String?
    @State private var showError = false
    
    private var groupedCompletions: [(provider: ModelProvider, completions: [ChatCompletion])] {
        let grouped = Dictionary(grouping: modelManager.completions, by: { $0.provider })
        return ModelProvider.allCases.compactMap { provider in
            guard let completions = grouped[provider], !completions.isEmpty else { return nil }
            return (provider, completions.sorted { $0.name < $1.name })
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header Section
            HStack {
                SettingsSectionHeader(
                    "Web API Connections",
                    subtitle: "Manage your API configurations"
                )
                Spacer()
                
                if !isAddingNewAPI && editingCompletion == nil {
                    Menu {
                        ForEach(modelManager.getAvailableProviders(), id: \.self) { provider in
                            Button(action: {
                                selectedProvider = provider
                                resetNewCompletionFields()
                                isAddingNewAPI = true
                            }) {
                                Label(provider.displayName, systemImage: providerIconName(provider))
                            }
                        }
                    } label: {
                        Label("Add Connection", systemImage: "plus.circle.fill")
                    }
                }
            }
            
            // Existing Configurations
            if modelManager.completions.isEmpty && !isAddingNewAPI && editingCompletion == nil {
                EmptyStateView {
                    isAddingNewAPI = true
                }
            } else if !isAddingNewAPI && editingCompletion == nil {
                configurationsList
            }
            
            // Add/Edit Form
            if isAddingNewAPI || editingCompletion != nil {
                configurationForm
            }
        }
        .maxWidth()
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete API Connection"),
                message: Text(
                    "Are you sure you want to delete '\(apiToDelete?.name ?? "")'? This action cannot be undone."
                ),
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
    
    // MARK: - Configurations List
    
    private var configurationsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedCompletions, id: \.provider) { group in
                VStack(alignment: .leading, spacing: 12) {
                    // Provider Header
                    HStack(spacing: 8) {
                        Image(systemName: providerIconName(group.provider))
                            .foregroundStyle(.primary)
                            .font(.system(size: 16, weight: .semibold))
                        Text(group.provider.displayName)
                            .font(.system(size: 14, weight: .semibold))
                        Text("(\(group.completions.count))")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Configuration Cards
                    VStack(spacing: 12) {
                        ForEach(group.completions, id: \.id) { completion in
                            ConfigurationCard(
                                completion: completion,
                                isDefault: modelManager.defaultCompletion?.id == completion.id,
                                onEdit: {
                                    prepareForEditing(completion)
                                },
                                onDelete: {
                                    apiToDelete = completion
                                    showDeleteConfirmation = true
                                },
                                onSetDefault: {
                                    modelManager.setDefaultConfiguration(completion)
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Configuration Form
    
    private var configurationForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Form Header
            HStack {
                Text(editingCompletion != nil ? "Edit API Connection" : "New API Connection")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                if isAddingNewAPI {
                    HStack(spacing: 6) {
                        Image(systemName: providerIconName(selectedProvider))
                            .font(.system(size: 12))
                        Text(selectedProvider.displayName)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(6)
                }
                
                Button(action: {
                    cancelForm()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Form Fields
            VStack(alignment: .leading, spacing: 16) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connection Name")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    TextField("e.g., My OpenAI API", text: $newCompletionName)
                }
                
                // Endpoint Field
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        isAddingNewAPI && selectedProvider == .ollama
                            ? "Endpoint URL *" : "Endpoint URL (optional)"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    TextField(
                        getDefaultEndpointForProvider(
                            isAddingNewAPI ? selectedProvider : editingCompletion!.provider
                        ),
                        text: $newCompletionEndpoint
                    )
                    .placeholder(when: newCompletionEndpoint.isEmpty) {
                        Text(
                            getDefaultEndpointForProvider(
                                isAddingNewAPI ? selectedProvider : editingCompletion!.provider
                            )
                        )
                        .foregroundStyle(.tertiary)
                    }
                }
                
                // API Key Field
                if (isAddingNewAPI && selectedProvider.requiresAPIKey)
                    || (editingCompletion != nil && editingCompletion!.provider.requiresAPIKey)
                {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Key *")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        SecureField("Enter your API key", text: $newCompletionApiKey)
                        Text("Your API key is stored securely and never shared")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Model Selection
                modelSelectionSection
            }
            
            Divider()
            
            // Form Actions
            HStack {
                Button("Cancel") {
                    cancelForm()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(editingCompletion != nil ? "Save Changes" : "Create Connection") {
                    if editingCompletion != nil {
                        updateExistingCompletion()
                    } else {
                        createNewCompletion()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
        .modifier(BorderDecoratedStyleModifier())
    }
    
    // MARK: - Model Selection Section
    
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model *")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            
            let currentCompletion =
                isAddingNewAPI
                ? ChatCompletion(
                    provider: selectedProvider,
                    name: newCompletionName,
                    endpoint: newCompletionEndpoint,
                    apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                    selectedModel: selectedModel?.id ?? manualModelName
                ) : editingCompletion!
            
            if modelRegistry.isLoading(for: currentCompletion) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fetching available models...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else if let error = modelRegistry.getError(for: currentCompletion) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Failed to fetch models")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Button("Retry") {
                            Task {
                                await modelRegistry.fetchModels(for: currentCompletion)
                            }
                        }
                        .font(.system(size: 12))
                        .buttonStyle(.bordered)
                    }
                    Text(error.localizedDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                let availableModels = modelRegistry.getModels(for: currentCompletion)
                
                if !availableModels.isEmpty {
                    // Model Picker
                    Menu {
                        ForEach(availableModels) { model in
                            Button(action: {
                                selectedModel = model
                                manualModelName = ""
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.displayName)
                                            .font(.system(size: 13))
                                        if let contextLength = model.contextLength {
                                            Text("Context: \(contextLength.formatted()) tokens")
                                                .font(.system(size: 11))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedModel?.id == model.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            selectedModel = nil
                            manualModelName = ""
                        }) {
                            Label("Enter manually", systemImage: "pencil")
                        }
                    } label: {
                        HStack {
                            Text(
                                selectedModel?.displayName
                                    ?? (manualModelName.isEmpty
                                        ? "Select a model" : manualModelName)
                            )
                            .foregroundStyle(
                                selectedModel != nil || !manualModelName.isEmpty
                                    ? .primary : .secondary
                            )
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 36)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                } else {
                    // Manual Entry
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("e.g., gpt-4, claude-3-sonnet", text: $manualModelName)
                            .placeholder(when: manualModelName.isEmpty) {
                                Text("Enter model name")
                                    .foregroundStyle(.tertiary)
                            }
                        
                        HStack {
                            Button(action: {
                                Task {
                                    await modelRegistry.fetchModels(for: currentCompletion)
                                }
                            }) {
                                Label("Fetch Models", systemImage: "arrow.clockwise")
                            }
                            .font(.system(size: 12))
                            .buttonStyle(.bordered)
                            .disabled(
                                newCompletionApiKey.isEmpty
                                    && (isAddingNewAPI
                                        ? selectedProvider : editingCompletion!.provider)
                                        .requiresAPIKey
                            )
                            
                            Spacer()
                            
                            Text("Enter model name manually or fetch from API")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        guard !newCompletionName.isEmpty else { return false }
        guard !(selectedModel == nil && manualModelName.isEmpty) else { return false }
        
        let provider = isAddingNewAPI ? selectedProvider : editingCompletion!.provider
        
        if provider.requiresAPIKey {
            guard !newCompletionApiKey.isEmpty else { return false }
        }
        
        if provider == .ollama {
            guard !newCompletionEndpoint.isEmpty else { return false }
            guard isValidURL(newCompletionEndpoint) else { return false }
        }
        
        return true
    }
    
    // MARK: - Actions
    
    private func createNewCompletion() {
        do {
            if selectedProvider == .ollama && !isValidURL(newCompletionEndpoint) {
                errorMessage = "Please enter a valid URL"
                showError = true
                return
            }
            
            let modelName = selectedModel?.id ?? manualModelName
            
            try modelManager.createCompletion(
                provider: selectedProvider,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty
                    ? getDefaultEndpointForProvider(selectedProvider) : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                selectedModel: modelName
            )
            
            cancelForm()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func updateExistingCompletion() {
        guard let editingCompletion = editingCompletion,
            let index = modelManager.completions.firstIndex(where: { $0.id == editingCompletion.id }
            )
        else {
            return
        }
        
        do {
            if editingCompletion.provider == .ollama && !isValidURL(newCompletionEndpoint) {
                errorMessage = "Please enter a valid URL"
                showError = true
                return
            }
            
            let modelName = selectedModel?.id ?? manualModelName
            
            modelManager.updateCompletion(
                at: index,
                name: newCompletionName,
                endpoint: newCompletionEndpoint.isEmpty
                    ? getDefaultEndpointForProvider(editingCompletion.provider)
                    : newCompletionEndpoint,
                apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
                selectedModel: modelName
            )
            
            cancelForm()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteCompletion(_ completion: ChatCompletion) {
        modelManager.deleteCompletion(withID: completion.id)
        apiToDelete = nil
    }
    
    private func prepareForEditing(_ completion: ChatCompletion) {
        newCompletionName = completion.name
        newCompletionEndpoint = completion.endpoint
        newCompletionApiKey = completion.apiKey ?? ""
        selectedProvider = completion.provider
        editingCompletion = completion
        
        selectedModel = nil
        manualModelName = completion.selectedModel
        
        // Try to find matching model in registry
        let availableModels = modelRegistry.getModels(for: completion)
        if let matchingModel = availableModels.first(where: {
            $0.id == completion.selectedModel || $0.name == completion.selectedModel
        }) {
            selectedModel = matchingModel
            manualModelName = ""
        }
        
        // Trigger model fetching if needed
        Task {
            await modelRegistry.fetchModels(for: completion)
        }
    }
    
    private func cancelForm() {
        isAddingNewAPI = false
        editingCompletion = nil
        resetNewCompletionFields()
    }
    
    private func resetNewCompletionFields() {
        newCompletionName = ""
        newCompletionEndpoint = ""
        newCompletionApiKey = ""
        selectedModel = nil
        manualModelName = ""
        selectedProvider = .openai
    }
    
    // MARK: - Helpers
    
    private func getDefaultEndpointForProvider(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "http://127.0.0.1:11434"
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .gemini: return "https://generativelanguage.googleapis.com"
        case .openrouter: return "https://openrouter.ai/api/v1"
        }
    }
    
    private func providerIconName(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "server.rack"
        case .openai: return "brain.head.profile"
        case .anthropic: return "atom"
        case .gemini: return "star.fill"
        case .openrouter: return "network"
        }
    }
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

// MARK: - Configuration Card

struct ConfigurationCard: View {
    let completion: ChatCompletion
    let isDefault: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Provider Icon
            Image(systemName: providerIconName(completion.provider))
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(completion.name)
                        .font(.system(size: 14, weight: .semibold))
                    
                    if isDefault {
                        Text("Default")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                    }
                    
                    if !completion.isValid {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(completion.selectedModel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(completion.endpoint)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                if !isDefault {
                    Button(action: onSetDefault) {
                        Image(systemName: "star")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("Set as default")
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Edit")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDefault ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
    
    private func providerIconName(_ provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "server.rack"
        case .openai: return "brain.head.profile"
        case .anthropic: return "atom"
        case .gemini: return "star.fill"
        case .openrouter: return "network"
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 4) {
                Text("No API Connections")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Add your first API connection to get started")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            
            Button(action: onAdd) {
                Label("Add Connection", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
