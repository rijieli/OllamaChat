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
