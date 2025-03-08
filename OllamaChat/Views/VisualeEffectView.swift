//
//  VisualeEffectView.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/8.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import AppKit
import SwiftUI

struct BackgroundVisualEffect {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let emphasized: Bool
}

struct BackgroundVisualEffectKey: EnvironmentKey {
    typealias Value = BackgroundVisualEffect?
    static var defaultValue: Value = nil
}

extension EnvironmentValues {
    var backgroundVisualEffect: BackgroundVisualEffect? {
        get { self[BackgroundVisualEffectKey.self] }
        set { self[BackgroundVisualEffectKey.self] = newValue }
    }

    var isDarkMode: Bool {
        return colorScheme == .dark
    }
}

struct VisualEffectView: NSViewRepresentable {
    private let material: NSVisualEffectView.Material
    private let blendingMode: NSVisualEffectView.BlendingMode
    private let isEmphasized: Bool

    fileprivate init(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode,
        emphasized: Bool
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = emphasized
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        NSVisualEffectView()
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = context.environment.backgroundVisualEffect?.material ?? material
        nsView.blendingMode =
            context.environment.backgroundVisualEffect?.blendingMode ?? blendingMode
        nsView.isEmphasized = context.environment.backgroundVisualEffect?.emphasized ?? isEmphasized
    }
}

extension View {
    /// usage: .visualEffect(material: .fullScreenUI)
    func visualEffect(
        material: NSVisualEffectView.Material,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        emphasized: Bool = false
    ) -> some View {
        self.background {
            VisualEffectView(
                material: material,
                blendingMode: blendingMode,
                emphasized: emphasized
            )
        }
    }
}
