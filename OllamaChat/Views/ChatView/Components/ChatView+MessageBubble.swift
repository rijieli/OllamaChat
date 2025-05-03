//
//  ChatView+MessageBubble.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/10.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import MarkdownUI
import SwiftUI

extension ChatView {
    
    struct MessageBubble: View {
        
        @ObservedObject var viewModel = ChatViewModel.shared
        
        @State var showTranslation = false
        
        let message: ChatMessage
        
        var isUser: Bool { message.role == .user }
        
        var body: some View {
            ChatBubble(isUser: isUser) {
                MarkdownTextView(
                    message: message.content,
                    isUser: isUser,
                    isCurrent: message == viewModel.messages.last
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .textSelection(.enabled)
                .background(isUser ? Color.blue : Color.ocAssistantBubbleBackground)
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
                .maxHeight()
                .frame(minWidth: 36)
            }
        }
        
        @ViewBuilder
        func contextButtons() -> some View {
            if isUser {
                MessageBubbleButton("Retry", "arrow.trianglehead.2.clockwise.rotate.90") {
                    viewModel.resendUntil(message)
                }
            }
            #if DEBUG
            MessageBubbleButton("Read", "speaker.wave.2") {
                TextSpeechCenter.shared.read(message.content)
            }
            #endif
            if #available(macOS 14.4, iOS 17.4, *) {
                MessageBubbleButton("Translate", "translate") {
                    showTranslation = true
                }
            }
            MessageBubbleButton("Edit", "bubble.and.pencil") {
                viewModel.editMessage(message)
            }
            MessageBubbleButton("Copy", "doc.on.doc") {
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
    }
    
    struct MessageBubbleButton: View {
        @State var hovered = false
        
        let title: LocalizedStringKey
        let systemName: String
        let action: VoidClosureOptionl
        
        init(
            _ title: LocalizedStringKey,
            _ systemName: String,
            action: VoidClosureOptionl
        ) {
            self.title = title
            self.systemName = systemName
            self.action = action
        }
        
        var body: some View {
            Button {
                action?()
            } label: {
                #if os(macOS)
                ZStack {
                    if hovered {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.black.opacity(0.05))
                            .padding(1)
                    }
                    Image(systemName: systemName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.primary.opacity(hovered ? 1 : 0.7))
                }
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .onHover { hovered = $0 }
                #else
                Label(title, systemImage: systemName)
                #endif
            }
            .buttonStyle(.simpleVisualEffect)
            .help(title)
        }
    }
}

private struct ChatBubble<Content: View, FloatingButtons: View>: View {
    @State var hovered = false
    
    let isUser: Bool
    let content: () -> Content
    let buttons: () -> FloatingButtons
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if isUser {
                    Spacer(minLength: 32)
                }
                content()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                if !isUser {
                    Spacer(minLength: 32)
                }
            }
            .contentShape(Rectangle())
            ZStack {
                if hovered {
                    buttons()
                        .maxWidth(alignment: isUser ? .trailing : .leading)
                        .transition(.opacity)
                }
            }
            .frame(height: 24)
            .padding(.top, 1)
            .padding(.bottom, 3)
            .animation(.default, value: hovered)
        }
        .onHover { hovered = $0 }
    }
}

private struct CollapsibleThinkBlock: View {
    let thinkContent: String
    let remainingContent: String
    let isThinking: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(isThinking ? "Thinking" : "Thought")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.right")
                        .frame(width: 12, height: 12)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.system(size: 12, weight: .medium))
                    
                    if isThinking {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }
                }
                .foregroundStyle(Color.secondary)
                .frame(height: 24)
                .maxWidth(alignment: .leading)
                .contentShape(.rect)
                .textSelection(.disabled)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                
                if isExpanded {
                    Text(thinkContent)
                        .maxWidth(alignment: .leading)
                        .font(.system(size: 12))
                        .lineSpacing(2)
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, 14)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(.secondary)
                                .opacity(0.5)
                                .frame(width: 2)
                                .frame(width: 8)
                        }
                        .padding(.vertical, 8)
                }
            }
            .tint(.blue)
            .animation(.default, value: isThinking)
            if !remainingContent.isEmpty {
                Markdown(remainingContent)
            }
        }
        .maxWidth(alignment: .leading)
    }
}

private struct MarkdownContent {
    let thinkContent: String
    let remainingContent: String
}

private struct MarkdownTextView: View {
    let message: String
    let isUser: Bool
    let isCurrent: Bool
    
    @State private var parsedContent: MarkdownContent?
    @StateObject var viewModel: ChatViewModel = .shared
    
    var body: some View {
        Group {
            if let parsedContent, !parsedContent.thinkContent.isEmpty {
                CollapsibleThinkBlock(
                    thinkContent: parsedContent.thinkContent,
                    remainingContent: parsedContent.remainingContent,
                    isThinking: isCurrent && viewModel.waitingResponse
                )
                .markdownTheme(.assistantTheme)
            } else {
                Markdown(message)
                    .markdownTheme(isUser ? .userTheme : .assistantTheme)
            }
        }
        .frame(minHeight: 24)
        .onChange(of: message) { _ in
            updateCache()
        }
        .onAppear {
            updateCache()
        }
    }
    
    private func updateCache(forceComplete: Bool = false) {
        let result = ThinkBlockParser.parse(markdownString: message)
        parsedContent = .init(
            thinkContent: result.thinkContent,
            remainingContent: result.remainingContent
        )
    }
}

extension MarkdownUI.Theme {
    static let assistantTheme: MarkdownUI.Theme = {
        var theme = Self.basic
        return
            theme
            .text {
                ForegroundColor(Color.ocAssistantBubbleForeground)
                BackgroundColor(nil)
                FontSize(13)
            }
    }()

    static let userTheme: MarkdownUI.Theme = {
        var theme = Self.basic
        return
            theme
            .text {
                ForegroundColor(Color.white)
                BackgroundColor(nil)
                FontSize(13)
            }
    }()
}
