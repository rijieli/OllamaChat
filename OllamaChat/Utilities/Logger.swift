//
//  Logger.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let general = Logger(subsystem: subsystem, category: "general")
}


let log = Logger.general
