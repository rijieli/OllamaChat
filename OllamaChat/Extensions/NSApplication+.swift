//
//  NSApplication+.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/2.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import AppKit

extension NSApplication {
    func canOpenURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }
}
