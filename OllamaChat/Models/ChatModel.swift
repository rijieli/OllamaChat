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
    let options: ChatOptions
}

struct ChatOptions: Codable {
    var temperature: Double
    var topP: Double
    var topK: Int
    var minP: Double
    var numPredict: Int
    var repeatLastN: Int
    var repeatPenalty: Double
    var seed: Int
    var numCtx: Int
    var mirostat: Int
    var mirostatEta: Double
    var mirostatTau: Double

    enum CodingKeys: String, CodingKey {
        case temperature, seed
        case numCtx = "num_ctx"
        case topP = "top_p"
        case topK = "top_k"
        case minP = "min_p"
        case numPredict = "num_predict"
        case repeatLastN = "repeat_last_n"
        case repeatPenalty = "repeat_penalty"
        case mirostat
        case mirostatEta = "mirostat_eta"
        case mirostatTau = "mirostat_tau"
    }
    
    static var defaultValue: ChatOptions {
        ChatOptions(
            temperature: 0.6,
            topP: 0.9,
            topK: 40,
            minP: 0.0,
            numPredict: -1,
            repeatLastN: 64,
            repeatPenalty: 1.1,
            seed: 0,
            numCtx: 2048,
            mirostat: 0,
            mirostatEta: 0.1,
            mirostatTau: 5.0
        )
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

    init(id: String? = nil, role: ChatMessageRole, content: String) {
        self.id = id ?? UUID().uuidString
        self.role = role
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let role = try container.decode(ChatMessageRole.self, forKey: .role)
        let content = try container.decode(String.self, forKey: .content)
        self.init(role: role, content: content)
    }

    var description: String {
        "\(role.rawValue) : \(content)"
    }

    static var globalSystem: Self {
        ChatMessage(role: .system, content: AppSettings.globalSystem)
    }
}
