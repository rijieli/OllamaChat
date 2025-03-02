//
//  UIApplication+Extension.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/2.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

#if os(macOS)
extension NSApplication {
    func canOpenURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }
}
#else
// For SwiftUI compatibility between platforms
extension UIApplication {
    static var shared: NSApplication {
        return NSApplication.shared
    }
    
    func canOpenURL(_ url: URL) -> Bool {
        return NSApplication.shared.canOpenURL(url)
    }
}
#endif
