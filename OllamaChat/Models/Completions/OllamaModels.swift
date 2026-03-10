//
//  OllamaModels.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

var APIEndPoint: String {
    APIManager.shared.endpoint + "/api/"
}

enum OllamaThinkSupport: Equatable {
    case unknown
    case supported
    case unsupported

    var showsThinkOption: Bool {
        self != .unsupported
    }

    var includesThinkInRequests: Bool {
        showsThinkOption
    }
}

enum JSONValue: Decodable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value."
            )
        }
    }
}

private struct DynamicCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

private func decodeAdditionalFields<K: CodingKey & CaseIterable>(
    from decoder: Decoder,
    excluding _: K.Type
) throws -> [String: JSONValue] {
    let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
    let knownFieldNames = Set(K.allCases.map(\.stringValue))

    return try dynamicContainer.allKeys.reduce(into: [:]) { result, key in
        guard !knownFieldNames.contains(key.stringValue) else { return }
        result[key.stringValue] = try dynamicContainer.decode(JSONValue.self, forKey: key)
    }
}

struct OllamaModelGroup: Decodable, Hashable {
    let models: [OllamaLanguageModel]
}

struct OllamaShowModelRequest: Encodable {
    let model: String
    let verbose: Bool?

    init(model: String, verbose: Bool? = nil) {
        self.model = model
        self.verbose = verbose
    }
}

enum OllamaShowModelCacheVariant: Hashable {
    case standard
    case verbose

    init(verbose: Bool?) {
        self = verbose == true ? .verbose : .standard
    }
}

struct OllamaShowModelResponse: Decodable, Hashable {
    let parameters: String?
    let license: String?
    let modifiedAt: String?
    let details: OllamaShowModelDetails?
    let template: String?
    let capabilities: [String]?
    let modelInfo: [String: JSONValue]?
    let additionalFields: [String: JSONValue]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case parameters
        case license
        case modifiedAt = "modified_at"
        case details
        case template
        case capabilities
        case modelInfo = "model_info"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parameters = try container.decodeIfPresent(String.self, forKey: .parameters)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        modifiedAt = try container.decodeIfPresent(String.self, forKey: .modifiedAt)
        details = try container.decodeIfPresent(OllamaShowModelDetails.self, forKey: .details)
        template = try container.decodeIfPresent(String.self, forKey: .template)
        capabilities = try container.decodeIfPresent([String].self, forKey: .capabilities)
        modelInfo = try container.decodeIfPresent([String: JSONValue].self, forKey: .modelInfo)
        additionalFields = try decodeAdditionalFields(from: decoder, excluding: CodingKeys.self)
    }

    var thinkSupport: OllamaThinkSupport {
        guard let capabilities else { return .unknown }
        return capabilities.contains("thinking") ? .supported : .unsupported
    }
}

struct OllamaShowModelDetails: Decodable, Hashable {
    let parentModel: String?
    let format: String?
    let family: String?
    let families: [String]?
    let parameterSize: String?
    let quantizationLevel: String?
    let additionalFields: [String: JSONValue]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case parentModel = "parent_model"
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parentModel = try container.decodeIfPresent(String.self, forKey: .parentModel)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        family = try container.decodeIfPresent(String.self, forKey: .family)
        families = try container.decodeIfPresent([String].self, forKey: .families)
        parameterSize = try container.decodeIfPresent(String.self, forKey: .parameterSize)
        quantizationLevel = try container.decodeIfPresent(String.self, forKey: .quantizationLevel)
        additionalFields = try decodeAdditionalFields(from: decoder, excluding: CodingKeys.self)
    }
}

struct OllamaModelParameter: Codable, Hashable {
    let format: String?
    let family: String?
    let families: [String]?
    let parameterSize: String?
    let quantizationLevel: String?

    enum CodingKeys: String, CodingKey {
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }

}

struct OllamaLanguageModel: Codable, Hashable {
    let name: String
    let model: String
    let remoteModel: String?
    let remoteHost: String?
    let modifiedAt: String
    let size: Int
    let digest: String
    let details: OllamaModelParameter?

    enum CodingKeys: String, CodingKey {
        case name
        case model
        case remoteModel = "remote_model"
        case remoteHost = "remote_host"
        case modifiedAt = "modified_at"
        case size
        case digest
        case details
    }

    static let emptyModel = OllamaLanguageModel(
        name: "",
        model: "",
        remoteModel: nil,
        remoteHost: nil,
        modifiedAt: "",
        size: 0,
        digest: "",
        details: nil
    )

    var modelInfo: ModelDisplayInfo {
        let fullName = name

        // Determine source and provider
        let source = fullName.hasPrefix("hf.co/") ? "HuggingFace" : "Ollama"
        let components = fullName.split(separator: "/")
        let provider: String?
        let modelNameWithScale: String

        if components.count > 1 {
            provider = source == "HuggingFace" ? String(components[1]) : String(components[0])
            modelNameWithScale = String(components.last!)
        } else {
            provider = nil
            modelNameWithScale = fullName
        }

        // Handle scale if present
        let parts = modelNameWithScale.split(separator: ":")
        var cleanModelName = String(parts[0])
        let scale = parts.count > 1 ? String(parts[1]).uppercased() : nil

        // Extract and remove parameter size suffixes first
        if let range = cleanModelName.range(of: "-[0-9]+[bB]", options: .regularExpression) {
            cleanModelName = String(cleanModelName[..<range.lowerBound])
        }

        // Remove technical suffixes
        let suffixesToRemove = [
            "-CoT-GGUF-Q[0-9]+",
            "-GGUF-Q[0-9]+",
            "-CoT",
            "-GGUF",
            "-Q[0-9]+",
        ]

        for suffix in suffixesToRemove {
            while let range = cleanModelName.range(
                of: suffix,
                options: [.regularExpression, .caseInsensitive]
            ) {
                cleanModelName = String(cleanModelName[..<range.lowerBound])
            }
        }

        // Add parameter size from details if available
        if let parameterSize = details?.parameterSize, !parameterSize.isEmpty {
            cleanModelName += "(\(parameterSize))"
        }

        return ModelDisplayInfo(
            source: source,
            provider: provider,
            modelName: cleanModelName.capitalized,
            modelScale: scale
        )
    }

    var fileSize: String {
        fileSizeFormatter.string(fromByteCount: Int64(size))
    }
}

extension OllamaLanguageModel {
    struct ModelDisplayInfo {
        let source: String
        let provider: String?
        let modelName: String
        let modelScale: String?
    }
}
