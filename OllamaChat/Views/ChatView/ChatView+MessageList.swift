//
//  ChatView+MessageList.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI
import Translation

extension ChatView {
    
    var messagesList: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text("This is the start of your chat")
                        .foregroundStyle(.secondary)
                        .padding()
                    let messages = viewModel.messages.filter { $0.role != .system }
                    ForEach(messages) { message in
                        let isUser = message.role == .user
                        MessageBubble(isUser: isUser, message: message)
                    }

                    Color.clear
                        .maxWidth()
                        .frame(height: 40)
                        .id(bottomID)

                }
                .maxFrame()
                //.defaultScrollAnchor(.bottom)
                .overlay(alignment: .bottom) {
                    HStack {
                        if speechCenter.isSpeaking {
                            actionButton("speaker.slash.fill") {
                                speechCenter.stopImmediate()
                            }
                        }
                        
                        if viewModel.waitingResponse {
                            actionButton("stop.fill") {
                                viewModel.work?.cancel()
                            }
                        }

                        actionButton("gearshape.fill") {
                            viewModel.showSystemConfig = true
                        }

                        actionButton("trash.fill") {
                            viewModel.resetChat()
                        }
                    }
                    .frame(height: 40)
                    .padding(.trailing, 12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .animation(.smooth, value: viewModel.waitingResponse)
                    .animation(.smooth, value: speechCenter.isSpeaking)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.messages) { _ in
                    proxy.scrollTo(bottomID)
                }
            }

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
                    .overlay {
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
                        .opacity(viewModel.waitingResponse ? 0 : 1)
                        .padding(.trailing, 12)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .animation(.default, value: viewModel.waitingResponse)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .maxFrame()
            .frame(height: 160)
        }
    }
    
    private func actionButton(_ sfName: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: sfName)
                .frame(width: 20, height: 20, alignment: .center)
                .frame(width: 40, height: 32)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue))
        }
        .buttonStyle(.noAnimationStyle)
        .transition(.opacity)
    }
}
