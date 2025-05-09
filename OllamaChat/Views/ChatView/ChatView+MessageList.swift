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
                .padding(.horizontal, 12)
                Color.clear.frame(height: 40)
                    .id(bottomID)
            }
            .maxFrame()
            //.defaultScrollAnchor(.bottom)
            .overlay(alignment: .bottom) {
                chatActionsView()
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
    
    var buttonHeight: CGFloat {
        CurrentOS.isiOS ? 36 : 32
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
                viewModel.showSystemConfig = true
            }
            
            if CurrentOS.isiOS, allowSubmitNewMessage {
                actionButton("arrow.up") {
                    viewModel.send()
                }
            }
        }
        .frame(height: 40)
        .maxWidth(alignment: .trailing)
        .clipped()
        .frame(maxWidth: .infinity, alignment: .trailing)
        .animation(.default, value: viewModel.waitingResponse)
        .animation(.default, value: speechCenter.isSpeaking)
        .animation(.default, value: allowSubmitNewMessage)
        .padding(.bottom, 0)
        .padding(.trailing, 12)
    }
    
    private func actionButton(_ sfName: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: sfName)
                .frame(width: 20, height: 20, alignment: .center)
                .frame(width: 40, height: buttonHeight)
                .foregroundStyle(.white)
                .background(Capsule().fill(Color.blue))
        }
        .buttonStyle(.noAnimationStyle)
        .transition(.opacity)
    }
}
