//
//  ModelEditingView.swift
//  OllamaChat
//
//  Created by Codex on 2026/3/7.
//

import SwiftUI

struct ModelEditingView: View {
    @Binding private var chatOptions: ChatOptions
    var showsResetButton = true

    init(chatOptions: Binding<ChatOptions>, showsResetButton: Bool = true) {
        _chatOptions = chatOptions
        self.showsResetButton = showsResetButton
    }
    
    private var thinkModeBinding: Binding<OllamaThinkMode> {
        Binding(
            get: { chatOptions.think },
            set: { chatOptions.think = $0 }
        )
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
                                "https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values"
                        )!
                    )
                }
                
                Spacer(minLength: 0)
                
                if showsResetButton {
                    Button("Reset to Default") {
                        chatOptions = .defaultValue
                    }
                }
            }
            
            LabeledContent("Thinking") {
                Picker("Thinking", selection: thinkModeBinding) {
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
            
            LabeledContent("Temperature (\(chatOptions.temperature, specifier: "%.2f"))")
            {
                Slider(value: $chatOptions.temperature, in: 0...2, step: 0.1)
            }
            
            LabeledContent("Top P (\(chatOptions.topP, specifier: "%.2f"))") {
                Slider(value: $chatOptions.topP, in: 0...1, step: 0.05)
            }
            
            LabeledContent(
                "Repeat Penalty (\(chatOptions.repeatPenalty, specifier: "%.2f"))"
            ) {
                Slider(value: $chatOptions.repeatPenalty, in: 0...2, step: 0.05)
            }
            
            LabeledContent("Repeat Last N") {
                TextField("", value: $chatOptions.repeatLastN, format: .number)
            }
            
            SettingsSectionHeader("Advanced Settings")
            
            VStack(alignment: .leading, spacing: 12) {
                Picker("Mirostat Mode", selection: $chatOptions.mirostat) {
                    Text("Disabled").tag(0)
                    Text("Mirostat 1.0").tag(1)
                    Text("Mirostat 2.0").tag(2)
                }
                .pickerStyle(.segmented)
                
                if chatOptions.mirostat > 0 {
                    LabeledContent(
                        "Eta (\(chatOptions.mirostatEta, specifier: "%.2f"))"
                    ) {
                        Slider(
                            value: $chatOptions.mirostatEta,
                            in: 0...1,
                            step: 0.05
                        )
                    }
                    
                    LabeledContent(
                        "Tau (\(chatOptions.mirostatTau, specifier: "%.2f"))"
                    ) {
                        Slider(
                            value: $chatOptions.mirostatTau,
                            in: 0...10,
                            step: 0.1
                        )
                    }
                }
                
                LabeledContent("Context Window") {
                    TextField("", value: $chatOptions.numCtx, format: .number)
                }
                
                LabeledContent("Max tokens to predict") {
                    TextField("", value: $chatOptions.numPredict, format: .number)
                }
                
                LabeledContent("Top K (\(chatOptions.topK))") {
                    TextField("", value: $chatOptions.topK, format: .number)
                }
                
                LabeledContent("Min P (\(chatOptions.minP, specifier: "%.2f"))") {
                    Slider(value: $chatOptions.minP, in: 0...1, step: 0.05)
                }
            }
            .maxWidth(alignment: .leading)
        }
        .labeledContentStyle(.settings)
        .maxWidth()
        .animation(.default, value: chatOptions.mirostat)
    }
}
