//
//  ChatViewModel+.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

extension ChatViewModel {
    var apiEndPoint: String {
        if host.isEmpty {
            return "http://127.0.0.1:" + (port.isEmpty ? "11434" : port) + "/api/"
        } else {
            return host + (port.isEmpty ? "" : ":" + port) + "/api/"
        }
    }
}
