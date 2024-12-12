//
//  IFLogger.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/12.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation

let logger = IFLogger.shared

extension IFLogger {
    public func info<T>(_ items: T) {
        #if DEBUG
            print("ℹ️", terminator: " ")
            print(items)
        #endif
    }

    public func error<T>(_ items: T) {
        #if DEBUG
            print("ℹ️🚨", terminator: " ")
            print(items)
        #endif
    }

    public func file(_ info: String, _ level: LogLevel = .info) {
        log(info, level: level)
    }
}

public class IFLogger {
    public static let shared = IFLogger()

    private let fileManager = FileManager.default
    private let logFileName = "app.log"
    private let logQueue = DispatchQueue(label: "logQueue")
    private let dateFormatter: DateFormatter
    private var logFileHandle: FileHandle?

    private var logFileURL: URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(logFileName)
    }

    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        createLogFile()
        openLogFileHandle()
    }

    deinit {
        logFileHandle?.closeFile()
    }

    private func createLogFile() {
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
    }

    private func openLogFileHandle() {
        logFileHandle = try? FileHandle(forWritingTo: logFileURL)
    }

    private func closeLogFileHandle() {
        logFileHandle?.closeFile()
    }

    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage =
            "\(timestamp) [\(level.rawValue.uppercased())] [\(fileName):\(line)] \(function) - \(message)\n"

        logQueue.async { [weak self] in
            guard let self = self, let data = logMessage.data(using: .utf8) else { return }
            self.logFileHandle?.seekToEndOfFile()
            self.logFileHandle?.write(data)
        }
    }

    public enum LogLevel: String {
        case debug, info, warning, error
    }
}
