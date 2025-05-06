//
//  ChatCompletion+Ollama.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

var APIEndPoint: String {
    ChatViewModel.shared.apiEndPoint
}

func fetchOllamaModels(timeout: Double? = nil) async throws -> OllamaModelGroup {
    let endpoint = APIEndPoint + "tags"

    guard let url = URL(string: endpoint) else {
        throw NetError.invalidURL(error: nil)
    }

    let data: Data
    let response: URLResponse

    let timeoutRequest = ChatViewModel.shared.timeoutRequest
    let timeoutResource = ChatViewModel.shared.timeoutResource

    do {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout ?? Double(timeoutRequest) ?? 60
        sessionConfig.timeoutIntervalForResource = Double(timeoutResource) ?? 604800
        (data, response) = try await URLSession(configuration: sessionConfig).data(from: url)
    } catch {
        throw NetError.unreachable(error: error)
    }

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw NetError.invalidResponse(error: nil)
    }
    let decoder = JSONDecoder()
    do {
        let decoded = try decoder.decode(OllamaModelGroup.self, from: data)
        await MainActor.run {
            if decoded.models.count == 0 {
                ChatViewModel.shared.errorModel = noModelsError(error: nil)
            } else {
                ChatViewModel.shared.tags = decoded
                ChatViewModel.shared.currentChat?.model = ChatViewModel.shared.model
                ChatViewModel.shared.clearError()
            }
        }
        return decoded
    } catch {
        throw NetError.invalidData(error: error)
    }
}

struct OllamaModelGroup: Decodable, Hashable {
    let models: [OllamaLanguageModel]
}

struct OllamaModelParameter: Codable, Hashable {
    let parentModel: String
    let format: String
    let family: String
    let families: [String]?
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

    static var emptyDetails: OllamaModelParameter {
        OllamaModelParameter(
            parentModel: "",
            format: "",
            family: "",
            families: nil,
            parameterSize: "",
            quantizationLevel: ""
        )
    }
}

struct OllamaLanguageModel: Codable, Hashable {
    let name: String
    let model: String
    let modifiedAt: String
    let size: Int
    let digest: String
    let details: OllamaModelParameter

    enum CodingKeys: String, CodingKey {
        case name
        case model
        case modifiedAt = "modified_at"
        case size
        case digest
        case details
    }

    static let emptyModel = OllamaLanguageModel(
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
            while let range = cleanModelName.range(
                of: suffix,
                options: [.regularExpression, .caseInsensitive]
            ) {
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

extension OllamaLanguageModel {
    struct ModelDisplayInfo {
        let source: String
        let provider: String?
        let modelName: String
        let modelScale: String?
    }
}
