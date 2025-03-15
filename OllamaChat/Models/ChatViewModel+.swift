//
//  ChatViewModel+.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

extension ChatViewModel {
    static func processAPIEndPoint(host: String, port: String) -> String {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = port.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let defaultOllamaEndPoint = "http://127.0.0.1:11434/api/"
        
        // Return default if both are empty
        if host.isEmpty && port.isEmpty {
            return defaultOllamaEndPoint
        }
        
        var components = URLComponents()
        
        // Determine scheme
        if host.lowercased().contains("https://") {
            components.scheme = "https"
        } else {
            components.scheme = "http"
        }
        
        // Clean and set host
        let cleanHost = host.replacingOccurrences(
            of: "^(https?://)",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        .split(separator: "/")
        .first
        .map(String.init) ?? ""
        
        components.host = cleanHost.isEmpty ? "127.0.0.1" : cleanHost
        
        // Handle port
        if let portNumber = Int(port) {
            components.port = portNumber
        } else if port.isEmpty && ["127.0.0.1", "localhost"].contains(components.host?.lowercased()) {
            components.port = 11434
        }
        
        components.path = "/api/"
        
        return components.url?.absoluteString ?? defaultOllamaEndPoint
    }
    
    var apiEndPoint: String {
        Self.processAPIEndPoint(host: host, port: port)
    }
}
