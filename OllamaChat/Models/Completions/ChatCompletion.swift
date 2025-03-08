//
//  ChatCompletion.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

protocol ChatCompletionAbility {
    func send(messages: [ChatMessage]) async
    func cancel() async
}

enum ModelProvider: String, Codable {
    case ollama
    case api
}

struct ChatCompletion: Codable, Identifiable {
    let id: String
    var provider: ModelProvider
    var name: String
    var endpoint: String
    var apiKey: String?
    var models: [String]
    var configJSONRaw: String?

    init(
        provider: ModelProvider,
        name: String,
        endpoint: String,
        apiKey: String?,
        models: [String] = [],
        configJSONRaw: String? = nil
    ) {
        self.id = UUID().uuidString
        self.provider = provider
        self.name = name
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.configJSONRaw = configJSONRaw
        self.models = models
    }
}
