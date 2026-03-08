//
//  ModelEditingView.swift
//  OllamaChat
//
//  Created by Codex on 2026/3/7.
//

import SwiftUI

struct ModelEditingView: View {
    @Binding private var chatConfiguration: ChatConfiguration
    var showsResetButton = true

    init(chatConfiguration: Binding<ChatConfiguration>, showsResetButton: Bool = true) {
        _chatConfiguration = chatConfiguration
        self.showsResetButton = showsResetButton
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    SettingsSectionHeader("Model Parameters")
                    Link(
                        "View Parameters Documentation",
                        destination: URL(
                            string:
                                "https://github.com/ollama/ollama/blob/main/docs/modelfile.mdx#valid-parameters-and-values"
                        )!
                    )
                }
                
                Spacer(minLength: 0)
                
                if showsResetButton {
                    Button("Reset to Default") {
                        chatConfiguration = .defaultValue
                    }
                }
            }
            
            LabeledContent("Thinking") {
                Picker("Thinking", selection: $chatConfiguration.think) {
                    ForEach(OllamaThinkMode.allCases) { thinkMode in
                        Text(thinkMode.displayName)
                            .tag(thinkMode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            Text(
                "Auto uses the model default. Low, Medium, and High only apply to models that support think levels, such as GPT-OSS."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            
            LabeledContent("Temperature (\(chatConfiguration.options.temperature, specifier: "%.2f"))")
            {
                Slider(value: $chatConfiguration.options.temperature, in: 0...2, step: 0.1)
            }
            
            LabeledContent("Top P (\(chatConfiguration.options.topP, specifier: "%.2f"))") {
                Slider(value: $chatConfiguration.options.topP, in: 0...1, step: 0.05)
            }
            
            LabeledContent(
                "Repeat Penalty (\(chatConfiguration.options.repeatPenalty, specifier: "%.2f"))"
            ) {
                Slider(value: $chatConfiguration.options.repeatPenalty, in: 0...2, step: 0.05)
            }

            LabeledContent(
                "Presence Penalty (\(chatConfiguration.options.presencePenalty, specifier: "%.2f"))"
            ) {
                Slider(value: $chatConfiguration.options.presencePenalty, in: 0...2, step: 0.05)
            }

            LabeledContent(
                "Frequency Penalty (\(chatConfiguration.options.frequencyPenalty, specifier: "%.2f"))"
            ) {
                Slider(value: $chatConfiguration.options.frequencyPenalty, in: 0...2, step: 0.05)
            }
            
            LabeledContent("Repeat Last N") {
                TextField("", value: $chatConfiguration.options.repeatLastN, format: .number)
            }
            
            LabeledContent("Context Window") {
                TextField("", value: $chatConfiguration.options.numCtx, format: .number)
            }
            
            LabeledContent("Max tokens to predict") {
                TextField("", value: $chatConfiguration.options.numPredict, format: .number)
            }
            
            LabeledContent("Top K (\(chatConfiguration.options.topK))") {
                TextField("", value: $chatConfiguration.options.topK, format: .number)
            }
            
            LabeledContent("Min P (\(chatConfiguration.options.minP, specifier: "%.2f"))") {
                Slider(value: $chatConfiguration.options.minP, in: 0...1, step: 0.05)
            }
        }
        .labeledContentStyle(.settings)
        .maxWidth()
    }
}
