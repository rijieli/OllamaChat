//
//  ChatView+SystemPrompt.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation
import SwiftUI

extension ChatView {

    struct SystemEditorView: View {

        @ObservedObject var viewModel = ChatViewModel.shared

        @State var systemPrompt: String = ""

        @FocusState private var isPopupFocused: Bool

        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("System Prompt")
                                    .font(.system(size: 18, weight: .bold))
                                    .maxWidth(alignment: .leading)
                                Text("This text will be sent at the start of the chat, which is also referred to as the Role System.")
                                    .font(.system(size: 12))
                                    .maxWidth(alignment: .leading)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                            ZStack {
                                TextEditor(text: $systemPrompt)
                                    .disableAutoQuotes()
                                    .font(.body)
                                    .onSubmit {
                                        updateSystem()
                                    }
                                    .focused(self.$isPopupFocused)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .background()

                            HStack {
                                Button("Cancel") {
                                    isPopupFocused = false
                                    viewModel.showSystemConfig = false
                                }

                                Button("Save") {
                                    updateSystem()
                                }
                            }
                            .frame(height: 32)
                            .maxWidth(alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    }
                    .maxFrame()
                }
            }
            .frame(minWidth: 360, minHeight: 300, idealHeight: 300)
            .task {
                systemPrompt =
                    viewModel.messages.first(where: { $0.role == .system })?.content ?? ""
                isPopupFocused = true
            }
        }

        func updateSystem() {
            viewModel.updateSystem(.init(role: .system, content: systemPrompt))
        }
    }

    struct MessageEditorView: View {

        @ObservedObject var viewModel = ChatViewModel.shared

        @State var info: String = ""

        @State var role: ChatMessageRole = .user

        @FocusState private var isPopupFocused: Bool

        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: 12) {
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
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .background()

                            HStack {
                                Button("Cancel") {
                                    isPopupFocused = false
                                    viewModel.showEditingMessage = false
                                    viewModel.editingCellIndex = nil
                                }

                                Button("Save") {
                                    saveChange(resendMessage: false)
                                }

                                if let idx = viewModel.editingCellIndex,
                                    viewModel.messages[idx].role == .user
                                {
                                    Button("Update") {
                                        saveChange(resendMessage: true)
                                    }
                                }
                            }
                            .frame(height: 32)
                            .maxWidth(alignment: .trailing)
                        }
                        .padding(12)
                    }
                    .maxFrame()
                }
            }
            .frame(minWidth: 360, minHeight: 300, idealHeight: 300)
            .task {
                let msg = viewModel.messages[viewModel.editingCellIndex!]
                info = msg.content
                role = msg.role
                isPopupFocused = true
            }
        }

        func saveChange(resendMessage: Bool) {
            viewModel.updateMessage(
                at: viewModel.editingCellIndex!,
                with: .init(role: role, content: info)
            )
            if resendMessage {
                viewModel.resendUntil(viewModel.messages[viewModel.editingCellIndex!])
            }
            viewModel.editingCellIndex = nil
            viewModel.showEditingMessage = false
        }
    }
}
