//
//  SystemEditorView.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

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
                            Text(
                                "This text will be sent at the start of the chat, which is also referred to as the Role System."
                            )
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
                                .strokeBorder(Color.ocDividerColor, lineWidth: 1)
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
                        #if os(iOS)
                        .buttonStyle(.borderedProminent)
                        #endif
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                }
                .maxFrame()
                .padding(.top, CurrentOS.isiOS ? 24 : 0)
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
