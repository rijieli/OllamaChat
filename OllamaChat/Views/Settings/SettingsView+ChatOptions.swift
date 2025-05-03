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
    @AppStorage("ChatOptionsView.showAdvancedSettings")
    private var showAdvancedSettings = false
    @State private var globalSystemPrompt = AppSettings.globalSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                HStack {
                    SettingsSectionHeader(
                        "Global System Prompt:",
                        subtitle: "Automatic apply to each chat."
                    )
                    Spacer(minLength: 0)
                    Button("Save") {
                        AppSettings.globalSystem = globalSystemPrompt
                    }
                }
                TextEditor(text: $globalSystemPrompt)
                    .disableAutoQuotes()
                    .font(.body)
                    .frame(height: 100)
                    .modifier(BorderDecoratedStyleModifier())
            }
            
            CommonSeparator(16)
            
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
                
                Button("Reset to Default") {
                    viewModel.chatOptions = .defaultValue
                }
            }

            LabeledContent("Temperature (\(viewModel.chatOptions.temperature, specifier: "%.2f"))")
            {
                Slider(value: $viewModel.chatOptions.temperature, in: 0...2, step: 0.1)
            }

            LabeledContent("Top P (\(viewModel.chatOptions.topP, specifier: "%.2f"))") {
                Slider(value: $viewModel.chatOptions.topP, in: 0...1, step: 0.05)
            }

            LabeledContent(
                "Repeat Penalty (\(viewModel.chatOptions.repeatPenalty, specifier: "%.2f"))"
            ) {
                Slider(value: $viewModel.chatOptions.repeatPenalty, in: 0...2, step: 0.05)
            }

            LabeledContent("Repeat Last N") {
                TextField("", value: $viewModel.chatOptions.repeatLastN, format: .number)
            }

            Button {
                showAdvancedSettings.toggle()
            } label: {
                HStack(spacing: 4) {
                    SettingsSectionHeader("Advanced Settings")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showAdvancedSettings ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            VStack {
                if showAdvancedSettings {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Mirostat Mode", selection: $viewModel.chatOptions.mirostat) {
                            Text("Disabled").tag(0)
                            Text("Mirostat 1.0").tag(1)
                            Text("Mirostat 2.0").tag(2)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.chatOptions.mirostat > 0 {
                            LabeledContent(
                                "Eta (\(viewModel.chatOptions.mirostatEta, specifier: "%.2f"))"
                            ) {
                                Slider(
                                    value: $viewModel.chatOptions.mirostatEta,
                                    in: 0...1,
                                    step: 0.05
                                )
                            }

                            LabeledContent(
                                "Tau (\(viewModel.chatOptions.mirostatTau, specifier: "%.2f"))"
                            ) {
                                Slider(
                                    value: $viewModel.chatOptions.mirostatTau,
                                    in: 0...10,
                                    step: 0.1
                                )
                            }
                        }

                        LabeledContent("Context Window") {
                            TextField("", value: $viewModel.chatOptions.numCtx, format: .number)
                        }

                        LabeledContent("Max tokens to predict") {
                            TextField("", value: $viewModel.chatOptions.numPredict, format: .number)
                        }

                        LabeledContent("Top K (\(viewModel.chatOptions.topK))") {
                            TextField("", value: $viewModel.chatOptions.topK, format: .number)
                        }

                        LabeledContent("Min P (\(viewModel.chatOptions.minP, specifier: "%.2f"))") {
                            Slider(value: $viewModel.chatOptions.minP, in: 0...1, step: 0.05)
                        }
                    }
                    .transition(.move(edge: .top))
                }
            }
            .maxWidth(alignment: .leading)
            .clipped()
            
            Color.clear.frame(height: 56)
        }
        .labeledContentStyle(.settings)
        .maxWidth()
        .animation(.default, value: showAdvancedSettings)
        .animation(.default, value: viewModel.chatOptions.mirostat)
    }
}
