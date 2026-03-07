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
    private let requestOptions: ChatRequestOptions
    private let thinkRequestValue: OllamaThinkRequestValue?

    init(
        model: String,
        messages: [ChatMessage],
        options: ChatOptions
    ) {
        self.model = model
        self.messages = messages
        requestOptions = ChatRequestOptions(options)
        thinkRequestValue = options.thinkRequestValue
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
        try container.encode(requestOptions, forKey: .options)
        try container.encode(true, forKey: .stream)
        try container.encodeIfPresent(thinkRequestValue, forKey: .think)
    }
}

struct ChatRequestOptions: Encodable {
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

    init(_ options: ChatOptions) {
        temperature = options.temperature
        topP = options.topP
        topK = options.topK
        minP = options.minP
        numPredict = options.numPredict
        repeatLastN = options.repeatLastN
        repeatPenalty = options.repeatPenalty
        seed = options.seed
        numCtx = options.numCtx
        mirostat = options.mirostat
        mirostatEta = options.mirostatEta
        mirostatTau = options.mirostatTau
    }

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
}

enum OllamaThinkMode: String, CaseIterable, Codable, Identifiable {
    case automatic
    case enabled
    case disabled
    case low
    case medium
    case high

    var id: Self { self }

    var displayName: String {
        switch self {
        case .automatic:
            return "Auto"
        case .enabled:
            return "On"
        case .disabled:
            return "Off"
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }

    var requestValue: OllamaThinkRequestValue? {
        switch self {
        case .automatic:
            return nil
        case .enabled:
            return .boolean(true)
        case .disabled:
            return .boolean(false)
        case .low:
            return .level("low")
        case .medium:
            return .level("medium")
        case .high:
            return .level("high")
        }
    }
}

enum OllamaThinkRequestValue: Encodable, Equatable {
    case boolean(Bool)
    case level(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .boolean(let value):
            try container.encode(value)
        case .level(let value):
            try container.encode(value)
        }
    }
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
    var think: OllamaThinkMode

    init(
        temperature: Double,
        topP: Double,
        topK: Int,
        minP: Double,
        numPredict: Int,
        repeatLastN: Int,
        repeatPenalty: Double,
        seed: Int,
        numCtx: Int,
        mirostat: Int,
        mirostatEta: Double,
        mirostatTau: Double,
        think: OllamaThinkMode
    ) {
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.minP = minP
        self.numPredict = numPredict
        self.repeatLastN = repeatLastN
        self.repeatPenalty = repeatPenalty
        self.seed = seed
        self.numCtx = numCtx
        self.mirostat = mirostat
        self.mirostatEta = mirostatEta
        self.mirostatTau = mirostatTau
        self.think = think
    }

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
        case think
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = try container.decode(Double.self, forKey: .temperature)
        topP = try container.decode(Double.self, forKey: .topP)
        topK = try container.decode(Int.self, forKey: .topK)
        minP = try container.decode(Double.self, forKey: .minP)
        numPredict = try container.decode(Int.self, forKey: .numPredict)
        repeatLastN = try container.decode(Int.self, forKey: .repeatLastN)
        repeatPenalty = try container.decode(Double.self, forKey: .repeatPenalty)
        seed = try container.decode(Int.self, forKey: .seed)
        numCtx = try container.decode(Int.self, forKey: .numCtx)
        mirostat = try container.decode(Int.self, forKey: .mirostat)
        mirostatEta = try container.decode(Double.self, forKey: .mirostatEta)
        mirostatTau = try container.decode(Double.self, forKey: .mirostatTau)

        let decodedThink = try container.decodeIfPresent(OllamaThinkMode.self, forKey: .think)
        assert(decodedThink != nil, "ChatOptions missing think mode; defaulting to automatic.")
        think = decodedThink ?? .automatic
    }

    var thinkRequestValue: OllamaThinkRequestValue? {
        think.requestValue
    }

    func encodedModelConfiguration() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            guard let encodedString = String(data: data, encoding: .utf8) else {
                assert(false, "Failed to convert chat options into a UTF-8 string.")
                return nil
            }

            return encodedString
        } catch {
            assert(false, "Failed to encode chat options: \(error)")
            return nil
        }
    }

    static func decodeModelConfiguration(from string: String?) -> ChatOptions? {
        guard let string else { return nil }
        guard let data = string.data(using: .utf8) else {
            assert(false, "Failed to convert modelConfiguration into UTF-8 data.")
            return nil
        }

        do {
            return try JSONDecoder().decode(ChatOptions.self, from: data)
        } catch {
            assert(false, "Failed to decode chat options: \(error)")
            return nil
        }
    }
    
    static var defaultValue: ChatOptions {
        ChatOptions(
            temperature: 0.8,
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
            mirostatTau: 5.0,
            think: .automatic
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

    static var globalSystem: Self {
        ChatMessage(role: .system, content: AppSettings.globalSystem)
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
