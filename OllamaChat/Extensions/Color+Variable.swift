//
//  Color+Variable.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/3.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

extension Color {
    public static var ocPrimaryBackground: Color {
        .dynamicColor(light: "#FFFFFF", dark: "#1A1A1A")
    }
    
    public static var ocDividerColor: Color {
        #if os(macOS)
        return Color(NSColor.separatorColor)
        #else
        return Color(UIColor.separator)
        #endif
    }
    
    public static var ocAssistantBubbleBackground: Color {
        .dynamicColor(light: "#EBEBEB", dark: "#2C2C2E")
    }
    
    public static var ocAssistantBubbleForeground: Color {
        .dynamicColor(light: "#000000", dark: "#F0F0F0")
    }
}
