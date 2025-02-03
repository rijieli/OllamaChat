//
//  Color+.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/22.
//

import Foundation
import Hue
import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Color {

    init(hex: String) {
        #if os(macOS)
        self.init(nsColor: .init(hex: hex))
        #else
        self.init(uiColor: .init(hex: hex))
        #endif
    }

    #if os(macOS)
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
    #else
    public static func dynamicColor(light: String, dark: String) -> Color {
        let lightColor = UIColor(hex: light)
        let darkColor = UIColor(hex: dark)
        return dynamicColor(light: lightColor, dark: darkColor)
    }

    public static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            UIColor(dynamicProvider: { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? dark : light
            })
        )
    }
    #endif
}
