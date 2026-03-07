//
//  ChatViewModel+.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

extension ChatViewModel {
    static func processBaseEndPoint(host: String, port: String) -> String {
        let host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let port = port.trimmingCharacters(in: .whitespacesAndNewlines)

        let defaultBaseEndPoint = "http://127.0.0.1:11434"

        if host.isEmpty && port.isEmpty {
            return defaultBaseEndPoint
        }

        var components = URLComponents()

        if host.lowercased().contains("https://") {
            components.scheme = "https"
        } else {
            components.scheme = "http"
        }

        let cleanHost = host.replacingOccurrences(
            of: "^(https?://)",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        .split(separator: "/")
        .first
        .map(String.init) ?? ""

        components.host = cleanHost.isEmpty ? "127.0.0.1" : cleanHost

        if let portNumber = Int(port) {
            components.port = portNumber
        } else if port.isEmpty && ["127.0.0.1", "localhost"].contains(components.host?.lowercased()) {
            components.port = 11434
        }

        return components.url?.absoluteString ?? defaultBaseEndPoint
    }

    static func processAPIEndPoint(host: String, port: String) -> String {
        processBaseEndPoint(host: host, port: port) + "/api/"
    }

    static func endpointComponents(from endpoint: String) -> (host: String, port: String) {
        guard let url = URL(string: endpoint), let endpointHost = url.host else {
            assert(false, "Invalid stored Ollama endpoint: \(endpoint)")
            return ("http://127.0.0.1", "11434")
        }

        let scheme = url.scheme ?? "http"
        let host = "\(scheme)://\(endpointHost)"
        let port: String

        if let endpointPort = url.port {
            port = String(endpointPort)
        } else if ["127.0.0.1", "localhost"].contains(endpointHost.lowercased()) {
            port = "11434"
        } else {
            port = ""
        }

        return (host, port)
    }
    
    var apiEndPoint: String {
        Self.processAPIEndPoint(host: host, port: port)
    }
}
