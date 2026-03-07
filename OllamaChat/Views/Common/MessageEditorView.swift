//
//  MessageEditorView.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct MessageEditorView: View {

    let originalMessage: ChatMessage

    @ObservedObject var viewModel = ChatViewModel.shared

    @State var info: String = ""
    @State var thinking: String = ""

    @FocusState private var isPopupFocused: Bool

    private var isAssistantMessage: Bool {
        originalMessage.role == .assistant
    }

    private var hasChanges: Bool {
        info != originalMessage.content
            || normalizedThinking(thinking) != normalizedThinking(originalMessage.thinking ?? "")
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    if isAssistantMessage {
                        Text("Message")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }

                    ZStack {
                        TextEditor(text: $info)
                            .disableAutoQuotes()
                            .font(.body)
                            .onSubmit {
                                saveChange(resendMessage: true)
                            }
                            .focused(self.$isPopupFocused)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8.variable(os26: 16))
                            .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                    )
                    .background()
                }
                .frame(maxHeight: .infinity, alignment: .top)

                if isAssistantMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thinking")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        ZStack {
                            TextEditor(text: $thinking)
                                .disableAutoQuotes()
                                .font(.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                        }
                        .frame(maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8.variable(os26: 16))
                                .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                        )
                        .background()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                Button("Cancel") {
                    isPopupFocused = false
                    viewModel.showEditingMessage = nil
                }

                if hasChanges {
                    Button("Save") {
                        saveChange(resendMessage: false)
                    }

                    if originalMessage.role == .user {
                        Button("Resend") {
                            saveChange(resendMessage: true)
                        }
                    }
                }
            }
            .frame(height: 32)
            .maxWidth(alignment: .trailing)
        }
        .padding(12)
        .frame(
            minWidth: 360,
            minHeight: isAssistantMessage ? 460 : 320,
            idealHeight: isAssistantMessage ? 460 : 320
        )
        .onAppear {
            info = originalMessage.content
            thinking = originalMessage.thinking ?? ""
            isPopupFocused = true
        }
    }

    func saveChange(resendMessage: Bool) {
        guard let index = viewModel.messages.firstIndex(where: { $0.id == originalMessage.id }) else {
            return
        }
        var updatedMessage = originalMessage
        updatedMessage.content = info
        updatedMessage.thinking = normalizedThinking(thinking)

        viewModel.updateMessage(
            at: index,
            with: updatedMessage
        )
        if resendMessage {
            viewModel.resendUntil(updatedMessage)
        }
        viewModel.showEditingMessage = nil
    }

    private func normalizedThinking(_ value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : value
    }
}
