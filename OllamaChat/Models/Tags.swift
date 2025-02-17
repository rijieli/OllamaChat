//
//  Tags.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Foundation

struct ModelGroup: Decodable, Hashable {
    let models: [LanguageModel]
}

struct ModelDisplayInfo {
    let source: String
    let provider: String?
    let modelName: String
    let modelScale: String?
}

struct ModelDetails: Codable, Hashable {
    let parentModel: String
    let format: String
    let family: String
    let families: [String]
    let parameterSize: String
    let quantizationLevel: String

    enum CodingKeys: String, CodingKey {
        case parentModel = "parent_model"
        case format
        case family
        case families
        case parameterSize = "parameter_size"
        case quantizationLevel = "quantization_level"
    }

    static var emptyDetails: ModelDetails {
        ModelDetails(
            parentModel: "",
            format: "",
            family: "",
            families: [],
            parameterSize: "",
            quantizationLevel: ""
        )
    }
}

struct LanguageModel: Codable, Hashable {
    let name: String
    let model: String
    let modifiedAt: String
    let size: Int
    let digest: String
    let details: ModelDetails

    enum CodingKeys: String, CodingKey {
        case name
        case model
        case modifiedAt = "modified_at"
        case size
        case digest
        case details
    }

    static let emptyModel = LanguageModel(
        name: "",
        model: "",
        modifiedAt: "",
        size: 0,
        digest: "",
        details: .emptyDetails
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
            while let range = cleanModelName.range(of: suffix, options: [.regularExpression, .caseInsensitive]) {
                cleanModelName = String(cleanModelName[..<range.lowerBound])
            }
        }
        
        // Add parameter size from details if available
        if !details.parameterSize.isEmpty {
            cleanModelName += "(\(details.parameterSize))"
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
