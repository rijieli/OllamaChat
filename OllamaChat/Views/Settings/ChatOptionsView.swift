//
//  ChatOptions.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct ChatOptionsView: View {
    @ObservedObject var viewModel: ChatViewModel = .shared
    @State private var showAdvancedSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Link(
                    "View Parameters Documentation",
                    destination: URL(
                        string:
                            "https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values"
                    )!
                )

                Spacer()

                Button("Reset to Default") {
                    viewModel.resetChatOptionsToDefault()
                }
            }
            .maxWidth(alignment: .leading)

            // Basic Settings
            sectionHeader("Basic Settings")

            LabeledContent("Temperature (\(viewModel.temperature, specifier: "%.2f"))") {
                Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
            }

            LabeledContent("Top P (\(viewModel.topP, specifier: "%.2f"))") {
                Slider(value: $viewModel.topP, in: 0...1, step: 0.05)
            }

            LabeledContent("Repeat Penalty (\(viewModel.repeatPenalty, specifier: "%.2f"))") {
                Slider(value: $viewModel.repeatPenalty, in: 0...2, step: 0.05)
            }

            LabeledContent("Repeat Last N") {
                TextField("", value: $viewModel.repeatLastN, format: .number)
            }

            sectionHeader("Advanced Settings")

            Picker("Mirostat Mode", selection: $viewModel.mirostat) {
                Text("Disabled").tag(0)
                Text("Mirostat 1.0").tag(1)
                Text("Mirostat 2.0").tag(2)
            }
            .pickerStyle(.segmented)

            if viewModel.mirostat > 0 {
                LabeledContent("Eta (\(viewModel.mirostatEta, specifier: "%.2f"))") {
                    Slider(value: $viewModel.mirostatEta, in: 0...1, step: 0.05)
                }

                LabeledContent("Tau (\(viewModel.mirostatTau, specifier: "%.2f"))") {
                    Slider(value: $viewModel.mirostatTau, in: 0...10, step: 0.1)
                }
            }

            LabeledContent("Context Window") {
                TextField("", value: $viewModel.numCtx, format: .number)
            }

            LabeledContent("Max tokens to predict") {
                TextField("", value: $viewModel.numPredict, format: .number)
            }

            LabeledContent("Top K (\(viewModel.topK))") {
                TextField("", value: $viewModel.topK, format: .number)
            }

            LabeledContent("Min P (\(viewModel.minP, specifier: "%.2f"))") {
                Slider(value: $viewModel.minP, in: 0...1, step: 0.05)
            }
        }
        .labeledContentStyle(.settings)
        .maxWidth()
        .padding(16)
    }

    func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
    }
}
