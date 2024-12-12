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
                    !viewModel.disabledButton ? viewModel.send() : nil
                }
                .disabled(viewModel.waitingResponse)
                .focused($promptFieldIsFocused)
                .onChange(of: viewModel.current.content) { _ in
                    viewModel.disabledButton = viewModel.current.content.isEmpty
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .opacity(viewModel.waitingResponse ? 0 : 1)
                .overlay(alignment: .trailing) {
                    ZStack {
                        if sendButtonVisible {
                            Button {
                                viewModel.send()
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 24))
                                    .frame(width: 20, height: 20, alignment: .center)
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
                    .frame(width: 40 + 12, height: 40, alignment: .leading)
                }
                .animation(.smooth(duration: 0.3), value: sendButtonVisible)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .maxFrame()
        .frame(height: 160)
    }
    
    private var sendButtonVisible: Bool {
        guard !viewModel.disabledButton else { return false }
        guard !viewModel.waitingResponse else { return false }
        return viewModel.current.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

}
