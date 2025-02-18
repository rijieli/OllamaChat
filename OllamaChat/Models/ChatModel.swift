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

struct ChatOptions: Encodable {
    let temperature: Double
    let topP: Double
    let topK: Int
    let minP: Double
    let numPredict: Int
    let repeatLastN: Int
    let repeatPenalty: Double
    let seed: Int
    let numCtx: Int
    let mirostat: Int
    let mirostatEta: Double
    let mirostatTau: Double
    
    enum CodingKeys: String, CodingKey {
        case temperature, seed
        case numCtx = "num_ctx"
        case topP = "top_p"
        case topK = "top_k"
        case minP = "min_p"
        case numPredict = "num_predict"
        case repeatLastN = "repeat_last_n"
        case repeatPenalty = "repeat_penalty"
        case mirostat, mirostatEta = "mirostat_eta"
        case mirostatTau = "mirostat_tau"
    }
}

enum ChatMessageRole: String, Codable {
    case system
    case user
    case assistant
}

struct ChatMessage: Identifiable, Encodable, Equatable, Hashable, Decodable, CustomStringConvertible
{

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
