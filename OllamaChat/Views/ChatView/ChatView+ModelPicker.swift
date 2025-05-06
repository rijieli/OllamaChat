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
        Picker("Model:", selection: modelBinding) {
            ForEach(viewModel.tags.models, id: \.self) { model in
                Text(model.modelInfo.modelName)
                    .tag(model)
                    .help(modelHelpText(for: model))
            }
        }
        .pickerStyle(.menu)
    }

    private func modelHelpText(for model: OllamaLanguageModel) -> String {
        var help = [String]()
        
        // Basic info
        if let provider = model.modelInfo.provider {
            help.append("Provider: \(provider)")
        }
        help.append("Size: \(model.fileSize)")
        
        // Model details
        if !model.details.family.isEmpty {
            help.append("Family: \(model.details.family)")
        }
        if !model.details.parentModel.isEmpty {
            help.append("Base Model: \(model.details.parentModel)")
        }
        if !model.details.format.isEmpty {
            help.append("Format: \(model.details.format)")
        }
        if !model.details.quantizationLevel.isEmpty {
            help.append("Quantization: \(model.details.quantizationLevel)")
        }
        
        // Source info
        help.append("Source: \(model.modelInfo.source)")
        
        return help.joined(separator: "\n")
    }

    private var modelBinding: Binding<OllamaLanguageModel> {
        .init(
            get: {
                viewModel.tags.models
                    .first {
                        $0.name == viewModel.model
                    }
                    ?? viewModel.tags.models.first
                    ?? OllamaLanguageModel.emptyModel
            },
            set: { model in
                viewModel.currentChat?.model = model.name
                CoreDataStack.shared.saveContext()
                viewModel.objectWillChange.send()
            }
        )
    }

}
