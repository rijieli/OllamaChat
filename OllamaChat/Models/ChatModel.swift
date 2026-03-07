//
//  PromptModel.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

struct PromptModel: Encodable {
    var prompt: String
    var model: String
    var system: String
}

struct ChatModel: Encodable {
    var model: String
    var messages: [ChatMessage]
    private let configuration: ChatConfiguration

    init(
        model: String,
        messages: [ChatMessage],
        configuration: ChatConfiguration
    ) {
        self.model = model
        self.messages = messages
        self.configuration = configuration
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case options
        case stream
        case think
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(configuration.options, forKey: .options)
        try container.encode(true, forKey: .stream)
        try container.encodeIfPresent(configuration.thinkRequestValue, forKey: .think)
    }
}

enum ChatMessageRole: String, Codable {
    case system
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable, Equatable, Hashable {

    var id: String
    var role: ChatMessageRole
    var content: String
    var thinking: String?

    init(id: String? = nil, role: ChatMessageRole, content: String, thinking: String? = nil) {
        self.id = id ?? UUID().uuidString
        self.role = role
        self.content = content
        self.thinking = thinking
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case thinking
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(thinking, forKey: .thinking)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedRole = try container.decodeIfPresent(ChatMessageRole.self, forKey: .role)
        assert(decodedRole != nil, "ChatMessage missing role; defaulting to assistant")

        let hasMessagePayload =
            container.contains(.content)
            || container.contains(.thinking)
        assert(hasMessagePayload, "ChatMessage missing both content and thinking")

        let role = decodedRole ?? .assistant
        let content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        let thinking = try container.decodeIfPresent(String.self, forKey: .thinking)
        self.init(role: role, content: content, thinking: thinking)
    }

    var description: String {
        "\(role.rawValue) : \(content)"
    }

    mutating func append(_ chunk: ChatStreamChunk) {
        if !chunk.content.isEmpty {
            content += chunk.content
        }

        if !chunk.thinking.isEmpty {
            thinking = (thinking ?? "") + chunk.thinking
        }
    }
}
