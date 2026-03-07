//
//  ChatConfiguration.swift
//  OllamaChat
//
//  Created by Roger on 2026/3/7.
//  Copyright © 2026 IdeasForm. All rights reserved.
//


import Foundation

struct ChatConfiguration: Codable {
    /// Controls Ollama's `think` request behavior when supported by the selected model. Default: `automatic`.
    var think: OllamaThinkMode = .automatic
    var options: ChatOptions = .defaultValue

    init(think: OllamaThinkMode = .automatic, options: ChatOptions = .defaultValue) {
        self.think = think
        self.options = options
    }

    var thinkRequestValue: OllamaThinkRequestValue? {
        think.requestValue
    }

    func encodedModelConfiguration() -> String? {
        do {
            let data = try JSONEncoder().encode(self)
            guard let encodedString = String(data: data, encoding: .utf8) else {
                assert(false, "Failed to convert chat configuration into a UTF-8 string.")
                return nil
            }

            return encodedString
        } catch {
            assert(false, "Failed to encode chat configuration: \(error)")
            return nil
        }
    }

    static func decodeModelConfiguration(from string: String?) -> ChatConfiguration? {
        guard let string else { return nil }
        guard let data = string.data(using: .utf8) else {
            assert(false, "Failed to convert modelConfiguration into UTF-8 data.")
            return nil
        }

        do {
            return try JSONDecoder().decode(ChatConfiguration.self, from: data)
        } catch {
            return nil
        }
    }

    static var defaultValue: ChatConfiguration {
        ChatConfiguration()
    }
}

struct ChatOptions: Codable {
    /// Sets the size of the context window used to generate the next token. Default: `2048`.
    var numCtx: Int = 2048
    /// Sets how far back for the model to look back to prevent repetition. `0` disables it and `-1` uses `num_ctx`. Default: `64`.
    var repeatLastN: Int = 64
    /// Sets how strongly to penalize repetitions. Default: `1.0`.
    var repeatPenalty: Double = 1.0
    /// Penalizes tokens that have already appeared in the generated text to reduce repetition. Default: `0.0`.
    var presencePenalty: Double = 0.0
    /// Penalizes tokens based on how often they have appeared in the generated text. Default: `0.0`.
    var frequencyPenalty: Double = 0.0
    /// The temperature of the model. Increasing it makes the answer more creative. Default: `0.8`.
    var temperature: Double = 0.8
    /// Sets the random number seed to use for generation. Default: `0`.
    var seed: Int = 0
    /// Sets the stop sequences to use. Multiple stop patterns may be specified. Default: none.
    var stop: [String] = []
    /// Maximum number of tokens to predict. `-1` means infinite generation. Default: `-1`.
    var numPredict: Int = -1
    /// Reduces the probability of generating nonsense. Default: `40`.
    var topK: Int = 40
    /// Works together with top-k. Higher values allow more diverse text. Default: `0.9`.
    var topP: Double = 0.9
    /// Alternative to top-p that filters out low-probability tokens relative to the most likely token. Default: `0.0`.
    var minP: Double = 0.0

    init() {}

    enum CodingKeys: String, CodingKey {
        case numCtx = "num_ctx"
        case repeatLastN = "repeat_last_n"
        case repeatPenalty = "repeat_penalty"
        case presencePenalty = "presence_penalty"
        case frequencyPenalty = "frequency_penalty"
        case temperature
        case seed
        case stop
        case numPredict = "num_predict"
        case topK = "top_k"
        case topP = "top_p"
        case minP = "min_p"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let stopSequences = stop.isEmpty ? nil : stop

        try container.encode(numCtx, forKey: .numCtx)
        try container.encode(repeatLastN, forKey: .repeatLastN)
        try container.encode(repeatPenalty, forKey: .repeatPenalty)
        try container.encode(presencePenalty, forKey: .presencePenalty)
        try container.encode(frequencyPenalty, forKey: .frequencyPenalty)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(seed, forKey: .seed)
        try container.encodeIfPresent(stopSequences, forKey: .stop)
        try container.encode(numPredict, forKey: .numPredict)
        try container.encode(topK, forKey: .topK)
        try container.encode(topP, forKey: .topP)
        try container.encode(minP, forKey: .minP)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ChatOptions()

        func decode<T: Decodable>(
            _ type: T.Type,
            forKey key: CodingKeys,
            defaultValue: T
        ) throws -> T {
            let decodedValue = try container.decodeIfPresent(type, forKey: key)
            return decodedValue ?? defaultValue
        }

        numCtx = try decode(Int.self, forKey: .numCtx, defaultValue: defaults.numCtx)
        repeatLastN = try decode(Int.self, forKey: .repeatLastN, defaultValue: defaults.repeatLastN)
        repeatPenalty = try decode(
            Double.self,
            forKey: .repeatPenalty,
            defaultValue: defaults.repeatPenalty
        )
        presencePenalty = try decode(
            Double.self,
            forKey: .presencePenalty,
            defaultValue: defaults.presencePenalty
        )
        frequencyPenalty = try decode(
            Double.self,
            forKey: .frequencyPenalty,
            defaultValue: defaults.frequencyPenalty
        )
        temperature = try decode(Double.self, forKey: .temperature, defaultValue: defaults.temperature)
        seed = try decode(Int.self, forKey: .seed, defaultValue: defaults.seed)
        stop = try decode([String].self, forKey: .stop, defaultValue: defaults.stop)
        numPredict = try decode(Int.self, forKey: .numPredict, defaultValue: defaults.numPredict)
        topK = try decode(Int.self, forKey: .topK, defaultValue: defaults.topK)
        topP = try decode(Double.self, forKey: .topP, defaultValue: defaults.topP)
        minP = try decode(Double.self, forKey: .minP, defaultValue: defaults.minP)
    }

    static var defaultValue: ChatOptions {
        ChatOptions()
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
