//
//  MarkdownTextView.swift
//  OllamaChat
//
//  Created by Roger on 2024/11/7.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import MarkdownUI
import SwiftUI

struct MarkdownTextView: View {
    let message: String
    
    let isUser: Bool

    var body: some View {
        Markdown(message)
            .markdownTheme(isUser ? .userTheme : .assistantTheme)
    }
}

extension MarkdownUI.Theme {
    static let assistantTheme: MarkdownUI.Theme = {
        var theme = Self.basic
        return theme
            .text {
                ForegroundColor(Color.black)
                BackgroundColor(nil)
                FontSize(13)
            }
    }()
    
    static let userTheme: MarkdownUI.Theme = {
        var theme = Self.basic
        return theme
            .text {
                ForegroundColor(Color.white)
                BackgroundColor(nil)
                FontSize(13)
            }
    }()
}
