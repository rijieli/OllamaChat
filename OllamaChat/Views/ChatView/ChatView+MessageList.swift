//
//  ChatView+MessageList.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI
import Translation

private let scrollDebounce = Debouncer(delay: 1)

extension ChatView {

    var messages: [ChatMessage] {
        viewModel.messages.filter { $0.role != .system }
    }

    private var paddingHorizontal: CGFloat {
        ChatView.padding + 8
    }

    var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text("This is the start of your chat")
                    .foregroundStyle(.secondary)
                    .padding()
                VStack(spacing: 0) {
                    ForEach(messages) {
                        MessageBubble(message: $0)
                    }
                }
                .padding(.horizontal, paddingHorizontal)
                .frame(maxWidth: ChatView.maxWidth)

                Color.clear.frame(height: 40)
                    .id(bottomID)
            }
            .maxFrame()
            //.defaultScrollAnchor(.bottom)
            .overlay(alignment: .bottom) {
                chatActionsView()
                    .padding(.horizontal, paddingHorizontal)
                    .frame(maxWidth: ChatView.maxWidth)
                    .padding(.bottom, 4)
            }
            .onChange(of: viewModel.scrollToBottomToggle) { newValue in
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onAppear {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onChange(of: viewModel.currentChat) { newValue in
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }

    private func chatActionsView() -> some View {
        HStack(spacing: 8) {
            if speechCenter.isSpeaking {
                actionButton("speaker.slash.fill") {
                    speechCenter.stopImmediate()
                }
            }

            if viewModel.waitingResponse {
                actionButton("stop.fill") {
                    viewModel.cancelTask()
                }
            }

            actionButton("gearshape.fill") {
                viewModel.showModelConfiguration = true
            }
        }
        .frame(height: 40)
        .maxWidth(alignment: .trailing)
        .clipped()
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.default, value: viewModel.waitingResponse)
        .animation(.default, value: speechCenter.isSpeaking)
        .animation(.default, value: allowSubmitNewMessage)
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
