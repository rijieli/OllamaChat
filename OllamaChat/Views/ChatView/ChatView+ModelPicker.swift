//
//  ChatView+ModelPicker.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/13.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

extension ChatView {

    func modelPicker() -> some View {
        Menu {
            // Show Ollama models separately from configurations
            Section(header: providerHeader(for: .ollama)) {
                ollamaLegacySection()
            }

            // Grouped configurations by provider (excluding Ollama)
            ForEach(groupedConfigurations.filter { $0.provider != .ollama }, id: \.provider) { group in
                Section(header: providerHeader(for: group.provider)) {
                    ForEach(group.configurations, id: \.id) { config in
                        Button(action: {
                            selectConfiguration(config)
                        }) {
                            ConfigurationRow(config: config)
                        }
                    }
                }
            }

            // Quick add button
            if !APIManager.shared.completions.isEmpty {
                Section {
                    Button("Add New Configuration") {
                        // Navigate to settings
                        // This would typically be handled through navigation
                    }
                }
            }
        } label: {
            HStack {
                // Provider icon
                if let config = APIManager.shared.defaultCompletion {
                    providerIcon(for: config.provider)
                        .foregroundColor(.primary)
                }

                // Model name
                Text(selectedConfigurationName.isEmpty ? "Select a configuration" : selectedConfigurationName.prefix(10))
                    .foregroundColor(hasSelectedConfiguration ? .primary : .secondary)

                Spacer()

                // Status indicator
                if let config = APIManager.shared.defaultCompletion {
                    StatusIndicator(isValid: config.isValid)

                    if config.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .menuStyle(.borderedButton)
    }

    private var groupedConfigurations: [(provider: ModelProvider, configurations: [ChatCompletion])] {
        let grouped = Dictionary(grouping: APIManager.shared.enabledConfigurations, by: \.provider)
        return ModelProvider.allCases.compactMap { provider in
            guard let models = grouped[provider], !models.isEmpty else { return nil }
            return (provider, models)
        }
    }

    private func providerHeader(for provider: ModelProvider) -> some View {
        HStack {
            providerIcon(for: provider)
            Text(provider.displayName)
        }
    }

    private func providerIcon(for provider: ModelProvider) -> some View {
        Image(systemName: systemIcon(for: provider))
            .foregroundColor(.primary)
    }

    private func systemIcon(for provider: ModelProvider) -> String {
        switch provider {
        case .ollama: return "server.rack"
        case .openai: return "brain.head.profile"
        case .anthropic: return "atom"
        case .gemini: return "star.fill"
        case .openrouter: return "network"
        }
    }

    private var selectedConfigurationName: String {
        // First check if current model is an Ollama model
        let currentModel = viewModel.model
        let ollamaModels = ChatViewModel.shared.tags.models.map { $0.name }

        if ollamaModels.contains(currentModel) {
            return currentModel
        }

        // Then check if there's a default configuration
        guard let config = APIManager.shared.defaultCompletion else {
            return "Select a configuration"
        }

        // For Ollama configuration, show the selected model name
        if config.provider == .ollama {
            return config.selectedModel
        }

        // For other providers, show the configuration display name
        return config.displayName
    }

    private var hasSelectedConfiguration: Bool {
        return APIManager.shared.defaultCompletion != nil
    }

    @ViewBuilder
    private func ollamaLegacySection() -> some View {
        let ollamaModels = ChatViewModel.shared.tags.models.map { $0.name }

        if ollamaModels.isEmpty {
            // Show error when no models are available
            Text("Ollama service not running")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .onAppear {}
        } else {
            // Show individual Ollama models
            ForEach(ollamaModels, id: \.self) { modelName in
                Button(action: {
                    selectOllamaModel(modelName)
                }) {
                    OllamaModelRow(
                        modelName: modelName,
                        isSelected: selectedOllamaModel == modelName
                    )
                }
            }
        }
    }

    private var selectedOllamaModel: String? {
        // Get the selected model from ChatViewModel
        let currentModel = viewModel.model

        // Check if current model is an Ollama model
        let ollamaModels = ChatViewModel.shared.tags.models.map { $0.name }
        if ollamaModels.contains(currentModel) {
            return currentModel
        }

        // Check if there's a default Ollama configuration
        if let ollamaConfig = APIManager.shared.defaultCompletion,
           ollamaConfig.provider == .ollama {
            return ollamaConfig.selectedModel
        }

        return nil
    }

    private func selectOllamaModel(_ model: String) {
        // Update ChatViewModel directly for Ollama models
        viewModel.currentChat?.model = model
        CoreDataStack.shared.saveContext()
        viewModel.objectWillChange.send()

        // Also update any existing Ollama configuration if present
        let apiManager = APIManager.shared
        if let ollamaConfigIndex = apiManager.completions.firstIndex(where: { $0.provider == .ollama }) {
            var updatedConfig = apiManager.completions[ollamaConfigIndex]
            updatedConfig.selectedModel = model

            do {
                try apiManager.updateConfiguration(updatedConfig)
                apiManager.setDefaultConfiguration(updatedConfig)
                apiManager.updateLastUsed(id: updatedConfig.id)
            } catch {
                print("Error updating Ollama configuration: \(error)")
            }
        }
    }

    private func selectConfiguration(_ config: ChatCompletion) {
        // Update APIManager
        APIManager.shared.setDefaultConfiguration(config)
        APIManager.shared.updateLastUsed(id: config.id)

        // Update chat
        viewModel.currentChat?.model = config.selectedModel
        CoreDataStack.shared.saveContext()

        // Update ChatViewModel by triggering objectWillChange
        // The model property is computed and will reflect the change
        viewModel.objectWillChange.send()
    }
}

// MARK: - Supporting Views

struct ConfigurationRow: View {
    let config: ChatCompletion

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(config.displayName)
                        .font(.body)
                    if config.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                }

                Text(config.selectedModel)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    StatusIndicator(isValid: config.isValid)

                    if let lastUsed = config.lastUsed {
                        Text("Last used: \(lastUsed, style: .relative) ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if !config.isValid {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
}

struct OllamaModelRow: View {
    let modelName: String
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(modelName)
                        .font(.body)
                        .foregroundColor(isSelected ? .primary : .primary)

                    if isSelected {
                        Text("Selected")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                }

                Text("Local Ollama")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    // Always show green indicator for local models
                    StatusIndicator(isValid: true)

                    Text("Local model")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
    }
}

struct StatusIndicator: View {
    let isValid: Bool

    var body: some View {
        Circle()
            .fill(isValid ? Color.green : Color.red)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1)
            )
    }
}
