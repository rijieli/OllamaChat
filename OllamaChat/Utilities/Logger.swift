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

let log = Log.self

public struct Log {
    static let prefix = "💬 "
    public static func debug(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.debug("\(prefix)\(evalMessage)")
        #endif
    }

    public static func warning(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.warning("\(prefix)\(evalMessage)")
        #endif
    }

    public static func error(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.error("\(prefix)\(evalMessage)")
        #endif
    }

}
