//
//  MarkdownTextView.swift
//  OllamaChat
//
//  Created by Roger on 2024/11/7.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import SwiftUI

struct MarkdownTextView: View {
    let message: String
    
    var body: some View {
        let content = LocalizedStringKey(message.trimmingCharacters(in: .whitespacesAndNewlines))
        Text(content)
    }
}
