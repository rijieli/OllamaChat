//
//  ChatBubble.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 09.10.23.
//  Used from: https://gist.github.com/prafullakumar/aa7af213d9e7530ee82aa6e8c92505b4

import SwiftUI

struct ChatBubble<Content>: View where Content: View {
    
    @State var hovered = false
    
    var onTapFloatingButton: (() -> Void)?
    
    let direction: ChatBubbleShape.Direction
    let content: () -> Content
    
    init(direction: ChatBubbleShape.Direction, onTapFloatingButton: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.direction = direction
        self.onTapFloatingButton = onTapFloatingButton
    }

    var body: some View {
        HStack {
            if direction == .right {
                Spacer(minLength: 32)
            }
            content()
                .mask { RoundedRectangle(cornerRadius: 12, style: .continuous) }
                .overlay(alignment: .leading) {
                    if let onTapFloatingButton, hovered {
                        Button {
                            let _ = print("Tapped")
                            onTapFloatingButton()
                        } label: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .offset(x: -30)
                        .buttonStyle(.plain)
                        .zIndex(1)
                    }
                }
            if direction == .left {
                Spacer(minLength: 32)
            }
        }
        .contentShape(Rectangle())
        //.whenHovered { hovered = $0 } This code block mouse click
        .padding([(direction == .left) ? .leading : .trailing, .top, .bottom], 12)
    }
}

enum ChatBubbleShape {
    enum Direction {
        case left
        case right
    }
}
