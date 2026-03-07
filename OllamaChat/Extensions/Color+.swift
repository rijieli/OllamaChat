//
//  Color+.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/22.
//

import Foundation
import Hue
import SwiftUI
import AppKit

extension Color {

    init(hex: String) {
        self.init(nsColor: .init(hex: hex))
    }

    public static func dynamicColor(light: String, dark: String) -> Color {
        let lightColor = NSColor(hex: light)
        let darkColor = NSColor(hex: dark)
        return dynamicColor(light: lightColor, dark: darkColor)
    }

    public static func dynamicColor(light: NSColor, dark: NSColor) -> Color {
        Color(
            NSColor(name: nil) { (appearance) -> NSColor in
                switch appearance.bestMatch(from: [.darkAqua, .aqua]) {
                case .darkAqua:
                    return dark
                default:
                    return light
                }
            }
        )
    }
}
