//
//  MessageEditorView.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

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
                        #if os(iOS)
                        .buttonStyle(.borderedProminent)
                        #endif
                    }
                    .padding(12)
                }
                .maxFrame()
                .padding(.top, CurrentOS.isiOS ? 24 : 0)
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
