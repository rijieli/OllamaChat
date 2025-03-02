//
//  ChatViewModel+.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

extension ChatViewModel {
    var apiEndPoint: String {
        return host + (port.isEmpty ? "" : ":" + port) + "/api/"
    }
}
