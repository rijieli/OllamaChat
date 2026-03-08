//
//  ChatView+MessageInput.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/13.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import AppKit
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
                .onChange(of: viewModel.waitingResponse) { newValue in
                    if newValue == false, !viewModel.requiresModelSelectionOverlay {
                        promptFieldIsFocused = true
                    }
                }

            if viewModel.requiresModelSelectionOverlay {
                missingModelOverlay
            }
        }
        .modifier(
            BorderDecoratedStyleModifier(
                paddingV: 16.variable(os26: 20),
                paddingH: 12.variable(os26: 16)
            )
        )
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
            .animation(.smooth(duration: 0.3), value: allowSubmitNewMessage)
        }
        .onChange(of: viewModel.requiresModelSelectionOverlay) { requiresOverlay in
            promptFieldIsFocused = !requiresOverlay && !viewModel.waitingResponse
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
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(viewModel.model.isEmpty ? "Model required" : "Model unavailable")

                }
                .font(.headline)

                Text(
                    {
                        if viewModel.model.isEmpty {
                            if modelRegistry.models.isEmpty {
                                return "No model is selected, and no models are installed right now."
                            }

                            return "No model is selected. Choose an existing model to keep chatting."
                        }

                        if let unavailableModelName = viewModel.unavailableCurrentChatModelName {
                            return overlayMessage(for: unavailableModelName)
                        }

                        assert(false, "Missing model overlay requires a missing or unavailable chat model.")
                        return modelRegistry.models.isEmpty
                            ? "No models are installed right now."
                            : "Choose an existing model to keep chatting."
                    }()
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                if !modelRegistry.models.isEmpty {
                    Menu {
                        ForEach(modelRegistry.models, id: \.name) { model in
                            Button(model.name) {
                                viewModel.selectAvailableModel(model.name)
                            }
                        }
                    } label: {
                        Label("Choose Model", systemImage: "server.rack")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Label("Open Settings", systemImage: "gearshape")
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            promptFieldIsFocused = false
                            SettingsViewModel.shared.selectedTab = .models
                        }
                    )
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        promptFieldIsFocused = false
                        SettingsViewModel.shared.selectedTab = .models
                        if #available(macOS 13.0, *) {
                            NSApp.sendAction(
                                Selector(("showSettingsWindow:")),
                                to: nil,
                                from: nil
                            )
                        } else {
                            NSApp.sendAction(
                                Selector(("showPreferencesWindow:")),
                                to: nil,
                                from: nil
                            )
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gearshape")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .maxFrame()
    }

    private func overlayMessage(for unavailableModelName: String) -> String {
        if modelRegistry.models.isEmpty {
            return "\"\(unavailableModelName)\" is no longer available. No models are installed right now."
        }

        return "\"\(unavailableModelName)\" is no longer available. Choose an existing model to keep chatting."
    }
}
