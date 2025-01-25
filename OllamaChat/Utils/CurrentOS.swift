//
//  CurrentOS.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//


enum CurrentOS {
    case iOS
    case macOS
    
    static var current: CurrentOS {
#if os(macOS)
        return .macOS
#else
        return .iOS
#endif
    }
    
    static var isiOS: Bool {
        return CurrentOS.current == .iOS
    }
    
    static var ismacOS: Bool {
        return CurrentOS.current == .macOS
    }
}