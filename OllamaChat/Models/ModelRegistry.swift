//
//  ModelRegistry.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

@MainActor
class ModelRegistry: ObservableObject {
    static let shared = ModelRegistry()

    @Published var models: [String: [AIModel]] = [:] // [providerID: [models]]
    @Published var isLoading: [String: Bool] = [:] // [providerID: isLoading]
    @Published var errors: [String: Error?] = [:] // [providerID: error]

    private init() {}

    struct AIModel: Identifiable, Codable {
        let id: String
        let name: String
        let displayName: String
        let provider: ModelProvider
        let contextLength: Int?

        init(id: String, name: String, displayName: String? = nil, provider: ModelProvider, contextLength: Int? = nil) {
            self.id = id
            self.name = name
            self.displayName = displayName ?? name
            self.provider = provider
            self.contextLength = contextLength
        }
    }

    func fetchModels(for completion: ChatCompletion) async {
        let providerID = completion.id

        guard isLoading[providerID] != true else { return }

        isLoading[providerID] = true
        errors[providerID] = nil

        defer {
            isLoading[providerID] = false
        }

        do {
            let fetchedModels = try await fetchModelsFromProvider(completion)
            models[providerID] = fetchedModels
        } catch {
            errors[providerID] = error
            print("Error fetching models for \(completion.name): \(error)")
        }
    }

    private func fetchModelsFromProvider(_ completion: ChatCompletion) async throws -> [AIModel] {
        switch completion.provider {
        case .ollama:
            return try await fetchOllamaModels(completion)
        case .openai:
            return fetchOpenAIModels()
        case .anthropic:
            return fetchAnthropicModels()
        case .gemini:
            return fetchGeminiModels()
        case .openrouter:
            return try await fetchOpenRouterModels(completion)
        }
    }

    // MARK: - Ollama Models
    private func fetchOllamaModels(_ completion: ChatCompletion) async throws -> [AIModel] {
        guard let url = URL(string: "\(completion.endpoint)/api/tags") else {
            throw ModelFetchError.invalidEndpoint
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)

        return response.models.map { model in
            AIModel(
                id: model.name,
                name: model.name,
                displayName: model.name,
                provider: .ollama,
                contextLength: model.details?.context_length
            )
        }
    }

    private struct OllamaModelsResponse: Codable {
        let models: [OllamaModel]
    }

    private struct OllamaModel: Codable {
        let name: String
        let modified_at: String?
        let size: Int64?
        let digest: String?
        let details: OllamaModelDetails?
    }

    private struct OllamaModelDetails: Codable {
        let format: String?
        let family: String?
        let families: [String]?
        let parameter_size: String?
        let quantization_level: String?
        let context_length: Int?
    }

    // MARK: - OpenAI Models (Static List)
    private func fetchOpenAIModels() -> [AIModel] {
        return [
            AIModel(id: "gpt-4o", name: "gpt-4o", displayName: "GPT-4o", provider: .openai, contextLength: 128000),
            AIModel(id: "gpt-4o-mini", name: "gpt-4o-mini", displayName: "GPT-4o Mini", provider: .openai, contextLength: 128000),
            AIModel(id: "gpt-4-turbo", name: "gpt-4-turbo", displayName: "GPT-4 Turbo", provider: .openai, contextLength: 128000),
            AIModel(id: "gpt-3.5-turbo", name: "gpt-3.5-turbo", displayName: "GPT-3.5 Turbo", provider: .openai, contextLength: 16385)
        ]
    }

    // MARK: - Anthropic Models (Static List)
    private func fetchAnthropicModels() -> [AIModel] {
        return [
            AIModel(id: "claude-3-5-sonnet-20241022", name: "claude-3-5-sonnet-20241022", displayName: "Claude 3.5 Sonnet", provider: .anthropic, contextLength: 200000),
            AIModel(id: "claude-3-5-haiku-20241022", name: "claude-3-5-haiku-20241022", displayName: "Claude 3.5 Haiku", provider: .anthropic, contextLength: 200000),
            AIModel(id: "claude-3-opus-20240229", name: "claude-3-opus-20240229", displayName: "Claude 3 Opus", provider: .anthropic, contextLength: 200000),
            AIModel(id: "claude-3-sonnet-20240229", name: "claude-3-sonnet-20240229", displayName: "Claude 3 Sonnet", provider: .anthropic, contextLength: 200000),
            AIModel(id: "claude-3-haiku-20240307", name: "claude-3-haiku-20240307", displayName: "Claude 3 Haiku", provider: .anthropic, contextLength: 200000)
        ]
    }

    // MARK: - Gemini Models (Static List)
    private func fetchGeminiModels() -> [AIModel] {
        return [
            AIModel(id: "gemini-2.0-flash-exp", name: "gemini-2.0-flash-exp", displayName: "Gemini 2.0 Flash (Experimental)", provider: .gemini),
            AIModel(id: "gemini-1.5-pro", name: "gemini-1.5-pro", displayName: "Gemini 1.5 Pro", provider: .gemini, contextLength: 2097152),
            AIModel(id: "gemini-1.5-flash", name: "gemini-1.5-flash", displayName: "Gemini 1.5 Flash", provider: .gemini, contextLength: 1048576),
            AIModel(id: "gemini-1.0-pro", name: "gemini-1.0-pro", displayName: "Gemini 1.0 Pro", provider: .gemini)
        ]
    }

    // MARK: - OpenRouter Models (API Fetch)
    private func fetchOpenRouterModels(_ completion: ChatCompletion) async throws -> [AIModel] {
        guard let apiKey = completion.apiKey else {
            throw ModelFetchError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/models")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ModelFetchError.unauthorized
        }

        let responseObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let data = responseObject?["data"] as? [[String: Any]] else {
            return []
        }

        return data.compactMap { modelDict in
            guard let id = modelDict["id"] as? String else { return nil }
            return AIModel(
                id: id,
                name: id,
                displayName: modelDict["name"] as? String ?? id,
                provider: .openrouter,
                contextLength: modelDict["context_length"] as? Int
            )
        }
    }

    // MARK: - Utility Methods
    func getModels(for completion: ChatCompletion) -> [AIModel] {
        return models[completion.id] ?? []
    }

    func isLoading(for completion: ChatCompletion) -> Bool {
        return isLoading[completion.id] ?? false
    }

    func getError(for completion: ChatCompletion) -> Error? {
        return errors[completion.id] ?? nil
    }

    func clearCache(for completion: ChatCompletion) {
        models.removeValue(forKey: completion.id)
        errors.removeValue(forKey: completion.id)
        isLoading.removeValue(forKey: completion.id)
    }

    func clearAllCache() {
        models.removeAll()
        errors.removeAll()
        isLoading.removeAll()
    }
}

// MARK: - Error Types
enum ModelFetchError: Error, LocalizedError {
    case invalidEndpoint
    case missingAPIKey
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid API endpoint URL"
        case .missingAPIKey:
            return "API key is required to fetch models"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .unauthorized:
            return "Authentication failed. Please check your API key."
        case .rateLimited:
            return "Rate limit exceeded. Please try again later."
        }
    }
}