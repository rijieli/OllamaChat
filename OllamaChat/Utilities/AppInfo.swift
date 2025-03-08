//
//  AppInfo.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/8.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import AppKit

enum AppInfo {

    static var info: [String: Any] {
        return Bundle.main.infoDictionary ?? [:]
    }

    static var version: String {
        info["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var build: String {
        info["CFBundleVersion"] as? String ?? "0"
    }

}
