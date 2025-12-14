//
//  LegacyAPI.swift
//  OllamaChat
//
//  Temporary file for backward compatibility
//

import Foundation

// Legacy API endpoint - should be removed after migration
var APIEndPoint: String {
    return "http://127.0.0.1:11434/api/"
}

// Legacy Ollama model structures - should be removed after migration
struct OllamaModelGroup: Decodable, Hashable {
    let models: [OllamaLanguageModel]
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

    var modelInfo: ModelDisplayInfo {
        let fullName = name

        // Simple display info since we don't have full details
        let parts = fullName.split(separator: ":")
        let modelName = String(parts[0])
        let scale = parts.count > 1 ? String(parts[1]).uppercased() : nil

        return ModelDisplayInfo(
            source: "Ollama",
            provider: nil,
            modelName: modelName,
            modelScale: scale
        )
    }

    struct ModelDisplayInfo {
        let source: String
        let provider: String?
        let modelName: String
        let modelScale: String?
    }
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
}

// Legacy fetchOllamaModels - should be removed after migration
func fetchOllamaModels(timeout: Double? = nil) async throws -> OllamaModelGroup {
    let endpoint = APIEndPoint + "tags"

    guard let url = URL(string: endpoint) else {
        throw NetError.invalidURL(error: nil)
    }

    let data: Data
    let response: URLResponse

    do {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout ?? 60
        sessionConfig.timeoutIntervalForResource = 604800
        (data, response) = try await URLSession(configuration: sessionConfig).data(from: url)
    } catch {
        throw NetError.unreachable(error: error)
    }

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw NetError.invalidResponse(error: nil)
    }

    let decoder = JSONDecoder()
    do {
        return try decoder.decode(OllamaModelGroup.self, from: data)
    } catch {
        throw NetError.invalidData(error: error)
    }
}