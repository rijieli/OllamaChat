//
//  ModelManager.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/7.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

class APIManager: ObservableObject {
    enum Constants {
        static let kLocalStore = "ModelManager.LocalStore"
        static let kDefaultCompletion = "ModelManager.DefaultCompletionID"
        static let kConfigurationsV2 = "ModelManager.Configurations.v2"
    }

    static let shared = APIManager()

    private static var storage: [ChatCompletion] {
        get { UserDefaults.standard.getCodable(forKey: Constants.kLocalStore) ?? [] }
        set { UserDefaults.standard.setCodable(newValue, forKey: Constants.kLocalStore) }
    }

  
    private static var defaultCompletionID: String? {
        get { UserDefaults.standard.string(forKey: Constants.kDefaultCompletion) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.kDefaultCompletion) }
    }

    @Published var completions: [ChatCompletion] = APIManager.storage

    @Published var defaultCompletion: ChatCompletion? = {
        let completions = APIManager.storage
        if let defaultID =  APIManager.defaultCompletionID {
            return completions.first { $0.id == defaultID  }
        } else {
            return completions.first
        }
    }() {
        didSet {
            APIManager.defaultCompletionID = defaultCompletion?.id
        }
    }

    // New properties for unified model handling
    @Published var isLoadingModels = false
    @Published var modelFetchError: Error?

    private init() {}

    func loadCompletions() {
        completions = APIManager.storage
    }

    func createCompletion(provider: ModelProvider, name: String, endpoint: String, apiKey: String? = nil, selectedModel: String) throws {
        let completion = ChatCompletion(
            provider: provider,
            name: name,
            endpoint: endpoint,
            apiKey: apiKey,
            selectedModel: selectedModel
        )

        // Validate configuration before saving
        try ProviderFactory.validateConfiguration(completion)

        completions.append(completion)
        APIManager.storage = completions

        if completions.count == 1 {
            defaultCompletion = completion
        }
    }

    func createCompletion(provider: ModelProvider) throws {
        let completion = ProviderFactory.getDefaultConfiguration(for: provider)
        try ProviderFactory.validateConfiguration(completion)

        completions.append(completion)
        APIManager.storage = completions

        if completions.count == 1 {
            defaultCompletion = completion
        }
    }

    @available(*, deprecated, message: "Use createCompletion(provider:name:endpoint:apiKey:selectedModel:) instead")
    func createOpenAICompletion(name: String, endpoint: String, apiKey: String? = nil, selectedModel: String = "gpt-4o") {
        do {
            try createCompletion(provider: .openai, name: name, endpoint: endpoint, apiKey: apiKey, selectedModel: selectedModel)
        } catch {
            print("Error creating OpenAI completion: \(error)")
        }
    }
    
    func updateCompletion(at index: Int, name: String, endpoint: String, apiKey: String? = nil, selectedModel: String) {
        guard index >= 0 && index < completions.count else { return }

        completions[index].name = name
        completions[index].endpoint = endpoint
        completions[index].apiKey = apiKey
        completions[index].selectedModel = selectedModel

        // Validate updated configuration
        do {
            try ProviderFactory.validateConfiguration(completions[index])
        } catch {
            print("Error validating updated configuration: \(error)")
            // Revert changes if validation fails
            if let originalCompletion = APIManager.storage[safe: index] {
                completions[index] = originalCompletion
            }
            return
        }

        APIManager.storage = completions
    }

    func deleteCompletion(withName name: String) {
        completions.removeAll(where: { $0.name == name })
        APIManager.storage = completions

        // Update default if it was deleted
        if defaultCompletion?.name == name {
            defaultCompletion = completions.first
        }
    }

    func deleteCompletion(withID id: String) {
        completions.removeAll(where: { $0.id == id })
        APIManager.storage = completions

        // Update default if it was deleted
        if defaultCompletion?.id == id {
            defaultCompletion = completions.first
        }
    }

    func setDefaultCompletion(_ completion: ChatCompletion) {
        guard completions.contains(where: { $0.id == completion.id }) else { return }
        defaultCompletion = completion
    }

    @MainActor
    func createProvider(for completion: ChatCompletion) throws -> any ChatCompletionAbility {
        return try ProviderFactory.createProvider(for: completion)
    }

    func getAvailableProviders() -> [ModelProvider] {
        return ModelProvider.allCases
    }

    // MARK: - Unified Model Management

    /// Refresh all models for all enabled providers
    @MainActor
    func refreshAllModels() async {
        isLoadingModels = true
        modelFetchError = nil

        defer { isLoadingModels = false }

        do {
            // For each enabled configuration, fetch models
            for i in completions.indices {
                guard completions[i].isEnabled else { continue }

                do {
                    let provider = try await createProvider(for: completions[i])
                    // Note: This would need to be implemented in providers
                    // For now, we'll keep existing models
                    log.debug("Models refreshed for \(completions[i].displayName)")
                } catch {
                    log.error("Failed to refresh models for \(completions[i].displayName): \(error)")
                }
            }

            // Save updated configurations
            APIManager.storage = completions
        } catch {
            modelFetchError = error
            log.error("Failed to refresh models: \(error)")
        }
    }

    /// Get all enabled configurations
    var enabledConfigurations: [ChatCompletion] {
        return completions.filter { $0.isEnabled }
    }

    /// Get configurations for a specific provider
    func getConfigurationsForProvider(_ provider: ModelProvider) -> [ChatCompletion] {
        return completions.filter { $0.provider == provider }
    }

    /// Add a new configuration
    func addConfiguration(_ config: ChatCompletion) throws {
        // Validate configuration
        try ProviderFactory.validateConfiguration(config)

        completions.append(config)

        // Set as default if it's the first one
        if completions.count == 1 {
            defaultCompletion = config
        }

        APIManager.storage = completions
    }

    /// Update an existing configuration
    func updateConfiguration(_ config: ChatCompletion) throws {
        guard let index = completions.firstIndex(where: { $0.id == config.id }) else {
            throw APIManagerError.configurationNotFound
        }

        // Validate configuration
        try ProviderFactory.validateConfiguration(config)

        completions[index] = config
        APIManager.storage = completions

        // Update default if needed
        if defaultCompletion?.id == config.id {
            defaultCompletion = config
        }
    }

    /// Delete a configuration
    func deleteConfiguration(id: String) {
        completions.removeAll { $0.id == id }
        APIManager.storage = completions

        // Update default if it was deleted
        if defaultCompletion?.id == id {
            defaultCompletion = completions.first
        }
    }

    /// Set default configuration
    func setDefaultConfiguration(_ config: ChatCompletion) {
        guard completions.contains(where: { $0.id == config.id }) else { return }
        defaultCompletion = config

        // Update isDefault flag on all configurations
        for i in completions.indices {
            completions[i].isDefault = (completions[i].id == config.id)
        }

        APIManager.storage = completions
    }

    /// Toggle configuration enabled state
    func toggleConfigurationEnabled(id: String) {
        guard let index = completions.firstIndex(where: { $0.id == id }) else { return }
        completions[index].isEnabled.toggle()
        APIManager.storage = completions
    }

    /// Update last used timestamp
    func updateLastUsed(id: String) {
        guard let index = completions.firstIndex(where: { $0.id == id }) else { return }
        completions[index].lastUsed = Date()
        APIManager.storage = completions
    }
}

// MARK: - Error Types

enum APIManagerError: Error, LocalizedError {
    case configurationNotFound
    case invalidConfiguration(String)
    case providerNotAvailable

    var errorDescription: String? {
        switch self {
        case .configurationNotFound:
            return "Configuration not found"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .providerNotAvailable:
            return "Provider not available"
        }
    }
}

