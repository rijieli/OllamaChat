//
//  ButtonStyle+.swift
//  OllamaChat
//
//  Created by Roger on 2025/5/3.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct NoAnimationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == NoAnimationButtonStyle {
    static var noAnimationStyle: NoAnimationButtonStyle {
        NoAnimationButtonStyle()
    }
}

struct SimpleVisualEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

extension ButtonStyle where Self == SimpleVisualEffectButtonStyle {
    static var simpleVisualEffect: SimpleVisualEffectButtonStyle {
        SimpleVisualEffectButtonStyle()
    }
}
