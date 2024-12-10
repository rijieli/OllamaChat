//
//  ChatView+MessageList.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

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
                        ChatBubble(
                            direction: isUser ? .right : .left,
                            floatingButtonsAlignment: .bottomTrailing
                        ) {
                            MarkdownTextView(message: message.content)
                                .foregroundStyle(isUser ? Color.white : .black)
                                .padding([.leading, .trailing], 8)
                                .padding([.top, .bottom], 8)
                                .textSelection(.enabled)
                                .background(isUser ? Color.blue : Color(hex: "#EBEBEB"))
                        } buttons: {
                            HStack(spacing: 4) {
                                if isUser {
                                    bubbleButton("arrow.clockwise.circle.fill") {
                                        viewModel.resendUntil(message)
                                    }
                                }
                                bubbleButton("pencil.circle.fill") {
                                    viewModel.editMessage(message)
                                }
                                bubbleButton("doc.on.doc.fill") {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()  // Clears the pasteboard before writing
                                    pasteboard.setString(message.content, forType: .string)
                                }
                            }
                            .frame(height: 24)
                            .frame(minWidth: 36)
                            .padding(.horizontal, 3)
                            .background {
                                Capsule().fill(.background)
                            }
                            .overlay {
                                Capsule().strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                            }
                            .offset(x: -4, y: -4)
                        }
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
                        if viewModel.waitingResponse {
                            actionButton("stop.fill") {
                                viewModel.work?.cancel()
                            }
                            .transition(.opacity)
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
    
}
