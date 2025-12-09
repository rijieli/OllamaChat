//
//  UnifiedModelRegistry.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI

/// Centralized model fetching and caching system for all providers
@MainActor
class UnifiedModelRegistry: ObservableObject {
    static let shared = UnifiedModelRegistry()

    @Published var isLoading = false
    @Published var error: Error?

    private var modelCache: [ModelProvider: [String]] = [:]
    private var lastFetchTime: [ModelProvider: Date] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    private init() {}

    // MARK: - Model Fetching

    /// Fetch all models for all enabled configurations
    func fetchAllModels() async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let apiManager = APIManager.shared
        let enabledConfigs = apiManager.enabledConfigurations

        // Group configurations by provider to avoid duplicate fetches
        let providers = Set(enabledConfigs.map { $0.provider })

        await withTaskGroup(of: Void.self) { group in
            for provider in providers {
                group.addTask {
                    await self.fetchModelsForProvider(provider)
                }
            }
        }
    }

    /// Fetch models for a specific provider
    private func fetchModelsForProvider(_ provider: ModelProvider) async {
        // Check cache first
        if let lastFetch = lastFetchTime[provider],
           Date().timeIntervalSince(lastFetch) < cacheTimeout,
           let cachedModels = modelCache[provider],
           !cachedModels.isEmpty {
            log.debug("Using cached models for \(provider.displayName)")
            return
        }

        do {
            log.debug("Fetching models for \(provider.displayName)")

            switch provider {
            case .ollama:
                let models = try await fetchOllamaModels()
                modelCache[provider] = models
                lastFetchTime[provider] = Date()

                // Update all Ollama configurations with the fetched models
                await updateOllamaConfigurations(with: models)

            case .openai, .anthropic, .gemini, .openrouter:
                // For web API providers, we use static model lists for now
                // This could be enhanced to fetch from the APIs in the future
                let models = getStaticModelsForProvider(provider)
                modelCache[provider] = models
                lastFetchTime[provider] = Date()

                // Update configurations
                await updateWebAPIConfigurations(provider: provider, with: models)
            }
        } catch {
            log.error("Failed to fetch models for \(provider.displayName): \(error)")
            self.error = error
        }
    }

    // MARK: - Ollama Model Fetching

    private func fetchOllamaModels() async throws -> [String] {
        // Try to get the first enabled Ollama configuration
        let endpoint: String
        if let ollamaConfig = APIManager.shared.enabledConfigurations
            .first(where: { $0.provider == .ollama }) {
            endpoint = ollamaConfig.endpoint
        } else {
            // Fall back to default local Ollama endpoint
            endpoint = "http://127.0.0.1:11434"
            log.debug("No Ollama configuration found, using default endpoint: \(endpoint)")
        }

        guard let url = URL(string: "\(endpoint)/api/tags") else {
            throw ModelRegistryError.invalidURL
        }

        log.debug("Fetching Ollama models from: \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)

        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            log.debug("Ollama API response status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw ModelRegistryError.networkError(URLError(.init(rawValue: httpResponse.statusCode)))
            }
        }

        struct OllamaResponse: Codable {
            let models: [OllamaModel]
        }

        struct OllamaModel: Codable {
            let name: String
            let size: Int64?
            let digest: String?
            let modified_at: String?
            let details: ModelDetails?
        }

        struct ModelDetails: Codable {
            let format: String?
            let family: String?
            let families: [String]?
            let parameter_size: String?
            let quantization_level: String?
        }

        let decodedResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        let modelNames = decodedResponse.models.map { $0.name }
        log.debug("Fetched \(modelNames.count) Ollama models: \(modelNames)")
        return modelNames
    }

    private func updateOllamaConfigurations(with models: [String]) async {
        let apiManager = APIManager.shared
        var completions = apiManager.completions

        // Check if there's an Ollama configuration
        let ollamaIndex = completions.firstIndex(where: { $0.provider == .ollama })

        if ollamaIndex == nil {
            // Create a default Ollama configuration if none exists
            let defaultOllamaConfig = ChatCompletion(
                provider: .ollama,
                name: "Local Ollama",
                endpoint: "http://127.0.0.1:11434",
                apiKey: nil,
                selectedModel: models.first ?? "llama2",
                models: models
            )
            completions.append(defaultOllamaConfig)
            log.debug("Created default Ollama configuration")
        } else {
            // Update existing Ollama configuration(s)
            for i in completions.indices {
                if completions[i].provider == .ollama {
                    completions[i].models = models

                    // Update selected model if it's not in the new list
                    if !models.contains(completions[i].selectedModel) {
                        completions[i].selectedModel = models.first ?? "llama2"
                    }

                    // Set metadata if available
                    if completions[i].metadata == nil {
                        completions[i].metadata = ModelMetadata()
                    }
                    completions[i].metadata?.source = "ollama"
                }
            }
        }

        apiManager.completions = completions
        UserDefaults.standard.setCodable(completions, forKey: APIManager.Constants.kLocalStore)
    }

    // MARK: - Web API Model Management

    private func getStaticModelsForProvider(_ provider: ModelProvider) -> [String] {
        switch provider {
        case .openai:
            return [
                "gpt-4o",
                "gpt-4o-mini",
                "gpt-4-turbo",
                "gpt-4",
                "gpt-3.5-turbo"
            ]
        case .anthropic:
            return [
                "claude-3-5-sonnet-20241022",
                "claude-3-5-haiku-20241022",
                "claude-3-opus-20240229",
                "claude-3-sonnet-20240229",
                "claude-3-haiku-20240307"
            ]
        case .gemini:
            return [
                "gemini-1.5-pro",
                "gemini-1.5-flash",
                "gemini-1.0-pro"
            ]
        case .openrouter:
            return [
                "anthropic/claude-3.5-sonnet",
                "anthropic/claude-3.5-haiku",
                "openai/gpt-4o",
                "openai/gpt-4o-mini",
                "google/gemini-pro-1.5",
                "meta-llama/llama-3.1-70b-instruct",
                "meta-llama/llama-3.1-8b-instruct"
            ]
        case .ollama:
            return []
        }
    }

    private func updateWebAPIConfigurations(provider: ModelProvider, with models: [String]) async {
        let apiManager = APIManager.shared
        var completions = apiManager.completions

        for i in completions.indices {
            if completions[i].provider == provider {
                completions[i].models = models

                // Set metadata if available
                if completions[i].metadata == nil {
                    completions[i].metadata = ModelMetadata()
                }
                completions[i].metadata?.source = provider.rawValue
            }
        }

        apiManager.completions = completions
        UserDefaults.standard.setCodable(completions, forKey: APIManager.Constants.kLocalStore)
    }

    // MARK: - Cache Management

    /// Clear cache for a specific provider
    func clearCache(for provider: ModelProvider) {
        modelCache.removeValue(forKey: provider)
        lastFetchTime.removeValue(forKey: provider)
    }

    /// Clear all cached models
    func clearAllCache() {
        modelCache.removeAll()
        lastFetchTime.removeAll()
    }

    /// Get cached models for a provider
    func getCachedModels(for provider: ModelProvider) -> [String]? {
        return modelCache[provider]
    }

    /// Force refresh models for a specific provider
    func refreshModels(for provider: ModelProvider) async {
        clearCache(for: provider)
        await fetchModelsForProvider(provider)
    }
}

// MARK: - Error Types

enum ModelRegistryError: Error, LocalizedError {
    case noOllamaConfiguration
    case invalidURL
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .noOllamaConfiguration:
            return "No Ollama configuration found"
        case .invalidURL:
            return "Invalid Ollama endpoint URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode model response: \(error.localizedDescription)"
        }
    }
}
