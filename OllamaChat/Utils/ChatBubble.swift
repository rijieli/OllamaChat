//
//  ChatBubble.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 09.10.23.
//  Used from: https://gist.github.com/prafullakumar/aa7af213d9e7530ee82aa6e8c92505b4

import SwiftUI

struct ChatBubble<Content: View, FloatingButtons: View>: View {
    
    @State var hovered = false
    
    let direction: ChatBubbleShape.Direction
    let floatingButtonsAlignment: Alignment
    let content: Content
    let buttons: FloatingButtons
    
    init(direction: ChatBubbleShape.Direction, floatingButtonsAlignment: Alignment = .bottomTrailing, @ViewBuilder content: () -> Content, @ViewBuilder buttons: () -> FloatingButtons) {
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
                .mask { RoundedRectangle(cornerRadius: 12, style: .continuous) }
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
