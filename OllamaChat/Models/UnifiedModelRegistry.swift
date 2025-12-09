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
        // Always use the default local Ollama endpoint
        // Ollama configurations are optional and for custom endpoints only
        let endpoint = "http://127.0.0.1:11434"

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

        // Also update ChatViewModel.tags for the legacy system
        var ollamaModels: [OllamaLanguageModel] = []

        for model in decodedResponse.models {
            // Create details separately to avoid complex expression
            let parentModel = ""
            let format = model.details?.format ?? ""
            let family = model.details?.family ?? ""
            let families = model.details?.families
            let parameterSize = model.details?.parameter_size ?? ""
            let quantizationLevel = model.details?.quantization_level ?? ""

            let details = OllamaModelParameter(
                parentModel: parentModel,
                format: format,
                family: family,
                families: families,
                parameterSize: parameterSize,
                quantizationLevel: quantizationLevel
            )

            let name = model.name
            let modifiedAt = model.modified_at ?? ""
            let size = Int(model.size ?? 0)
            let digest = model.digest ?? ""

            let ollamaModel = OllamaLanguageModel(
                name: name,
                model: name,
                modifiedAt: modifiedAt,
                size: size,
                digest: digest,
                details: details
            )

            ollamaModels.append(ollamaModel)
        }

        await MainActor.run {
            ChatViewModel.shared.tags = OllamaModelGroup(models: ollamaModels)
        }

        return modelNames
    }

    private func updateOllamaConfigurations(with models: [String]) async {
        let apiManager = APIManager.shared
        var completions = apiManager.completions

        // Update existing Ollama configuration(s) if they exist
        // Don't auto-create configurations - Ollama is handled separately via ChatViewModel.tags
        var hasOllamaConfig = false
        for i in completions.indices {
            if completions[i].provider == .ollama {
                hasOllamaConfig = true
                completions[i].models = models

                // Update selected model if it's not in the new list
                if !models.contains(completions[i].selectedModel) && !models.isEmpty {
                    completions[i].selectedModel = models.first ?? "llama2"
                }

                // Set metadata if available
                if completions[i].metadata == nil {
                    completions[i].metadata = ModelMetadata()
                }
                completions[i].metadata?.source = "ollama"
            }
        }

        // Only save if there are Ollama configurations
        if hasOllamaConfig {
            apiManager.completions = completions
            UserDefaults.standard.setCodable(completions, forKey: APIManager.Constants.kLocalStore)
        }
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
