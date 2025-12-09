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
            // Header with refresh button
            Section(header: HStack {
                Text("Models")
                Spacer()
                if UnifiedModelRegistry.shared.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: {
                        Task {
                            await UnifiedModelRegistry.shared.fetchAllModels()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }) {
                if APIManager.shared.enabledConfigurations.isEmpty {
                    Text("No configurations available")
                        .foregroundColor(.secondary)
                }
            }

            // Grouped configurations by provider
            ForEach(groupedConfigurations, id: \.provider) { group in
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
                Text(selectedConfigurationName)
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
        guard let config = APIManager.shared.defaultCompletion else {
            return "Select Model"
        }
        return config.displayName
    }

    private var hasSelectedConfiguration: Bool {
        return APIManager.shared.defaultCompletion != nil
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
