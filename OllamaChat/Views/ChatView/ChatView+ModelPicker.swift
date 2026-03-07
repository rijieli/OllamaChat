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
            ollamaSection()
        } label: {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.primary)

                Text(
                    selectedModelDisplayName.isEmpty
                        ? "Select a model" : String(selectedModelDisplayName.prefix(16))
                )
                .foregroundColor(hasSelectedModel ? .primary : .secondary)
                
                Spacer()

                StatusIndicator(isValid: apiManager.configuration.isValid)
                
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

    @ViewBuilder
    private func ollamaSection() -> some View {
        if viewModel.tags.models.isEmpty {
            Text("Ollama service not running")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        } else {
            ForEach(viewModel.tags.models, id: \.name) { model in
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

    private var selectedModelDisplayName: String {
        displayName(for: selectedOllamaModel) ?? ""
    }

    private var hasSelectedModel: Bool {
        selectedOllamaModel != nil
    }

    private var selectedOllamaModel: String? {
        let currentModel = viewModel.model
        if !currentModel.isEmpty {
            return currentModel
        }

        if !apiManager.selectedModel.isEmpty {
            return apiManager.selectedModel
        }

        return nil
    }

    private func displayName(for modelName: String?) -> String? {
        guard let modelName, !modelName.isEmpty else { return nil }

        if let ollamaModel = viewModel.tags.models.first(where: { $0.name == modelName }) {
            let displayInfo = ollamaModel.modelInfo
            var displayName = displayInfo.modelName
            if let scale = displayInfo.modelScale {
                displayName += ":\(scale)"
            }
            return displayName
        }

        return modelName
    }

    private func selectOllamaModel(_ model: String) {
        viewModel.selectAvailableModel(model)
    }
}

// MARK: - Supporting Views

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
                
                Text("Local model")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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
