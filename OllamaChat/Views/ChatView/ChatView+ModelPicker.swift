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
                Text(model.modelInfo.modelName).tag(model)
            }
        }
        .pickerStyle(.menu)
    }

    private var modelBinding: Binding<LanguageModel> {
        .init(
            get: {
                viewModel.tags.models
                    .first {
                        $0.name == viewModel.model
                    }
                    ?? viewModel.tags.models.first
                    ?? LanguageModel.emptyModel
            },
            set: { model in
                viewModel.model = model.name
            }
        )
    }

}
