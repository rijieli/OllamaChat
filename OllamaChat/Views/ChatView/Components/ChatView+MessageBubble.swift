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
        
        @State var showTranslation = false
        @State var hovered = false
        
        let message: ChatMessage
        
        var isUser: Bool { message.role == .user }
        
        var body: some View {
            VStack(spacing: 0) {
                MarkdownTextView(
                    content: message.markdownContent
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .textSelection(.enabled)
                .background(isUser ? Color.blue : Color.ocAssistantBubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .ifTranslationPresentation(isPresented: $showTranslation, text: message.content)
                .padding(.leading, isUser ? 32 : 0)
                .padding(.trailing, isUser ? 0 : 23)
                .maxWidth(alignment: isUser ? .trailing : .leading)
                .contentShape(Rectangle())
                
                ZStack {
                    if hovered {
                        BubbleContextMenu(message: message, showTranslation: $showTranslation)
                            .maxHeight()
                            .frame(minWidth: 36)
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
    
    struct BubbleContextMenu: View {
        let message: ChatMessage
        @Binding var showTranslation: Bool
        var isUser: Bool { message.role == .user }
        @StateObject var viewModel = ChatViewModel.shared
        
        var body: some View {
            HStack(spacing: 0) {
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

private struct CollapsibleThinkBlock: View {
    let content: MarkdownContent
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
                    Text(content.think)
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
            if !content.message.isEmpty {
                Markdown(content.message)
                    .padding(.bottom, 4)
            }
        }
        .maxWidth(alignment: .leading)
    }
}

private struct MarkdownTextView: View {
    @StateObject var viewModel = ChatViewModel.shared
    let content: MarkdownContent
    
    var body: some View {
        if !content.think.isEmpty {
            let isThinking =
                content.isIncomplete
                && viewModel.waitingResponse
            
            CollapsibleThinkBlock(
                content: content,
                isThinking: isThinking
            )
            .markdownTheme(.assistantTheme)
            .frame(minHeight: 24)
        } else {
            Markdown(content.message)
                .markdownTheme(content.isUser ? .userTheme : .assistantTheme)
                .frame(minHeight: 12)
        }
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

struct MarkdownContent: Hashable {
    let think: String
    let message: String
    let isIncomplete: Bool
    let isUser: Bool
}

extension ChatMessage {
    
    var markdownContent: MarkdownContent {
        let (think, message, isIncomplete) = ThinkBlockParser.parse(markdownString: content)
        return MarkdownContent(
            think: think,
            message: message,
            isIncomplete: isIncomplete,
            isUser: role == .user
        )
    }
    
}
