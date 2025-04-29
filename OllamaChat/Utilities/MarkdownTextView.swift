//
//  MarkdownTextView.swift
//  OllamaChat
//
//  Created by Roger on 2024/11/7.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import MarkdownUI
import SwiftUI

struct CollapsibleThinkBlock: View {
    let thinkContent: String
    let remainingContent: String
    let isThinking: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text(isThinking ? "Thinking..." : "Thinking")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if isThinking {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                }
                .frame(height: 28)
                .contentShape(.rect)
                .textSelection(.disabled)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                
                if isExpanded {
                    Text(thinkContent)
                        .maxWidth()
                        .font(.system(size: 13))
                        .foregroundStyle(Color.ocAssistantBubbleForeground)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                }
            }
            .tint(.blue)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            }
            .animation(.default, value: isThinking)
            if !remainingContent.isEmpty {
                Markdown(remainingContent)
            }
        }
    }
}

struct MarkdownTextView: View {
    let message: String
    let isUser: Bool
    
    @State private var cachedParsedContent:
        (message: String, thinkContent: String, remainingContent: String, isIncomplete: Bool)?

    private var parsedContent: (thinkContent: String, remainingContent: String, isIncomplete: Bool)
    {
        if let cached = cachedParsedContent, cached.message == message {
            return (cached.thinkContent, cached.remainingContent, cached.isIncomplete)
        }
        // Parse immediately if no cache available
        return ThinkBlockParser.parse(markdownString: message)
    }
    
    var body: some View {
        Group {
            if parsedContent.isIncomplete || !parsedContent.thinkContent.isEmpty {
                CollapsibleThinkBlock(
                    thinkContent: parsedContent.thinkContent,
                    remainingContent: parsedContent.remainingContent,
                    isThinking: parsedContent.isIncomplete
                )
                .markdownTheme(.assistantTheme)
            } else {
                Markdown(message)
                    .markdownTheme(isUser ? .userTheme : .assistantTheme)
            }
        }
        .onChange(of: message) { _ in
            updateCache()
        }
        .onAppear {
            updateCache()
        }
    }
    
    private func updateCache() {
        let result = ThinkBlockParser.parse(markdownString: message)
        cachedParsedContent = (
            message: message,
            thinkContent: result.thinkContent,
            remainingContent: result.remainingContent,
            isIncomplete: result.isIncomplete
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
