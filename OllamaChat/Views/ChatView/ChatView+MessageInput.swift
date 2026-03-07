//
//  ChatView+MessageInput.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/13.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

extension ChatView {
    
    var messageInput: some View {
        ZStack {
            TextEditor(text: $viewModel.current.content)
                .disableAutoQuotes()
                .font(.body)
                .onSubmit {
                    if allowSubmitNewMessage {
                        viewModel.send()
                    }
                }
                .disabled(viewModel.waitingResponse || viewModel.requiresModelSelectionOverlay)
                .focused($promptFieldIsFocused)
                .modifier(BorderDecoratedStyleModifier())
                .overlay(alignment: .trailing) {
                    ZStack {
                        if allowSubmitNewMessage
                            && !viewModel.requiresModelSelectionOverlay
                        {
                            Button {
                                viewModel.send()
                                promptFieldIsFocused = false
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.blue)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut(.return, modifiers: .command)
                            .transition(.scale)
                            .help("⌘ + Return")
                        }
                    }
                }
                .animation(.smooth(duration: 0.3), value: allowSubmitNewMessage)
                .onChange(of: viewModel.waitingResponse) { newValue in
                    if newValue == false, !viewModel.requiresModelSelectionOverlay {
                        promptFieldIsFocused = true
                    }
                }

            if viewModel.requiresModelSelectionOverlay {
                missingModelOverlay
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
            }
        }
        .onChange(of: viewModel.unavailableCurrentChatModelName) { unavailableModel in
            promptFieldIsFocused = unavailableModel == nil && !viewModel.waitingResponse
        }
        .maxFrame()
        .frame(height: 160)
        .padding(.bottom, ChatView.padding)
        .background(alignment: .bottom) {
            Color.ocPrimaryBackground.frame(height: 50)
        }
    }
    
    var allowSubmitNewMessage: Bool {
        guard !viewModel.requiresModelSelectionOverlay else { return false }
        guard !viewModel.current.content.isEmpty else { return false }
        guard !viewModel.waitingResponse else { return false }
        return viewModel.current.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            == false
    }

    private var missingModelOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Model unavailable")
                        .font(.headline)

                    if let unavailableModelName = viewModel.unavailableCurrentChatModelName {
                        Text(overlayMessage(for: unavailableModelName))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                if !viewModel.availableReplacementModels.isEmpty {
                    Menu {
                        ForEach(viewModel.availableReplacementModels, id: \.name) { model in
                            Button(model.name) {
                                viewModel.selectAvailableModel(model.name)
                            }
                        }
                    } label: {
                        Label("Choose Model", systemImage: "server.rack")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    promptFieldIsFocused = false
                    viewModel.openModelSettings()
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .maxFrame(alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.ocPrimaryBackground.opacity(0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }

    private func overlayMessage(for unavailableModelName: String) -> String {
        if viewModel.availableReplacementModels.isEmpty {
            return "\"\(unavailableModelName)\" is no longer available. No models are installed right now."
        }

        return "\"\(unavailableModelName)\" is no longer available. Choose an existing model to keep chatting."
    }
}
