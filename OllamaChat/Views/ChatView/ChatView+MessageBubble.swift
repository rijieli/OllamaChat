//
//  ChatView+MessageBubble.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

extension ChatView {

    struct MessageBubble: View {

        @ObservedObject var viewModel = ChatViewModel.shared

        @State var showTranslation = false

        let isUser: Bool
        let message: ChatMessage

        var body: some View {
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
                    .ifTranslationPresentation(isPresented: $showTranslation, text: message.content)
                    #if os(iOS)
                    .contentShape(.contextMenuPreview, .rect(cornerRadius: 8))
                    .contextMenu {
                        contextButtons()
                    }
                    #endif
            } buttons: {
                HStack(spacing: 0) {
                    contextButtons()
                }
                .frame(height: 24)
                .frame(minWidth: 36)
                .padding(.horizontal, 4)
                .background {
                    Capsule().fill(.background)
                }
                .overlay {
                    Capsule().strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                }
                .offset(x: -4, y: -4)
            }
        }
        
        @ViewBuilder
        func contextButtons() -> some View {
            if isUser {
                bubbleButton("Retry" , "arrow.clockwise.circle.fill") {
                    viewModel.resendUntil(message)
                }
            }
            bubbleButton("Read", "speaker.wave.2.bubble.left") {
                TextSpeechCenter.shared.read(message.content)
            }
            if #available(macOS 14.4, iOS 17.4, *) {
                bubbleButton("Translate", "translate") {
                    showTranslation = true
                }
            }
            bubbleButton("Edit", "pencil.circle.fill") {
                viewModel.editMessage(message)
            }
            bubbleButton("Copy", "doc.on.doc.fill") {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()  // Clears the pasteboard before writing
                pasteboard.setString(message.content, forType: .string)
                #else
                let pasteboard = UIPasteboard.general
                pasteboard.string = message.content
                #endif
            }
        }

        func bubbleButton(_ title: String, _ systemName: String, action: VoidClosureOptionl) -> some View {
            Button {
                action?()
            } label: {
                #if os(macOS)
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .font(.system(size: 10, weight: .bold))
                    .padding(4)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
                #else
                Label(title, systemImage: systemName)
                #endif
            }
            .buttonStyle(.noAnimationStyle)
        }
    }

}

private struct ChatBubble<Content: View, FloatingButtons: View>: View {

    @State var hovered = false

    let direction: ChatBubbleShape.Direction
    let floatingButtonsAlignment: Alignment
    let content: Content
    let buttons: FloatingButtons

    init(
        direction: ChatBubbleShape.Direction,
        floatingButtonsAlignment: Alignment = .bottomTrailing,
        @ViewBuilder content: () -> Content,
        @ViewBuilder buttons: () -> FloatingButtons
    ) {
        self.content = content()
        self.direction = direction
        self.buttons = buttons()
        self.floatingButtonsAlignment = floatingButtonsAlignment
    }

    var body: some View {
        HStack {
            if direction == .right {
                Spacer(minLength: 32)
            }
            content
                .mask { RoundedRectangle(cornerRadius: 12) }
                .overlay(alignment: floatingButtonsAlignment) {
                    if hovered {
                        buttons.fixedSize().zIndex(1)
                    }
                }
            if direction == .left {
                Spacer(minLength: 32)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .padding([(direction == .left) ? .leading : .trailing, .top, .bottom], 12)
    }
}

enum ChatBubbleShape {
    enum Direction {
        case left
        case right
    }
}


struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension ButtonStyle where Self == NoAnimationButtonStyle {
    static var noAnimationStyle: NoAnimationButtonStyle {
        NoAnimationButtonStyle()
    }
}
