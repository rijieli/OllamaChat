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
            ForEach(
                groupedConfigurations.filter { $0.provider != .ollama },
                id: \.provider.rawValue
            ) { group in
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
        } label: {
            HStack {
                // Provider icon
                if let config = APIManager.shared.defaultCompletion {
                    providerIcon(for: config.provider)
                        .foregroundColor(.primary)
                }
                
                // Model name
                Text(
                    selectedConfigurationName.isEmpty
                        ? "Select a configuration" : selectedConfigurationName.prefix(16)
                )
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
    
    private var groupedConfigurations: [(provider: ModelProvider, configurations: [ChatCompletion])]
    {
        let grouped = Dictionary(
            grouping: APIManager.shared.enabledConfigurations,
            by: { $0.provider }
        )
        return ModelProvider.allCases.compactMap { provider in
            guard let configurations = grouped[provider], !configurations.isEmpty else {
                return nil
            }
            // Ensure all configurations in this group have the correct provider
            let validConfigs = configurations.filter { $0.provider == provider }
            guard !validConfigs.isEmpty else { return nil }
            return (provider, validConfigs)
        }
    }
    
    @ViewBuilder
    private func providerHeader(for provider: ModelProvider) -> some View {
        HStack {
            providerIcon(for: provider)
            Text(provider.displayName)
        }
        .id("header-\(provider.rawValue)")  // Explicit ID to prevent view reuse issues
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
        
        // Try to find the Ollama model and use its processed display name
        if let ollamaModel = ChatViewModel.shared.tags.models.first(where: {
            $0.name == currentModel
        }) {
            // Use the processed model name from modelInfo
            let displayInfo = ollamaModel.modelInfo
            var displayName = displayInfo.modelName
            if let scale = displayInfo.modelScale {
                displayName += ":\(scale)"
            }
            return displayName
        }
        
        // Then check if there's a default configuration
        guard let config = APIManager.shared.defaultCompletion else {
            return "Select a configuration"
        }
        
        // For Ollama configuration, try to find and use processed name
        if config.provider == .ollama {
            if let ollamaModel = ChatViewModel.shared.tags.models.first(where: {
                $0.name == config.selectedModel
            }) {
                let displayInfo = ollamaModel.modelInfo
                var displayName = displayInfo.modelName
                if let scale = displayInfo.modelScale {
                    displayName += ":\(scale)"
                }
                return displayName
            }
            // Fallback to raw model name if not found
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
        let ollamaModels = ChatViewModel.shared.tags.models
        
        if ollamaModels.isEmpty {
            // Show error when no models are available
            Text("Ollama service not running")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .onAppear {}
        } else {
            // Show individual Ollama models with processed display names
            ForEach(ollamaModels, id: \.name) { model in
                Button(action: {
                    selectOllamaModel(model.name)
                }) {
                    OllamaModelRow(
                        model: model,
                        isSelected: selectedOllamaModel == model.name
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
            ollamaConfig.provider == .ollama
        {
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
        if let ollamaConfigIndex = apiManager.completions.firstIndex(where: {
            $0.provider == .ollama
        }) {
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
    let model: OllamaLanguageModel
    let isSelected: Bool
    
    private var displayName: String {
        let displayInfo = model.modelInfo
        var name = displayInfo.modelName
        if let scale = displayInfo.modelScale {
            name += ":\(scale)"
        }
        return name
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(displayName)
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
