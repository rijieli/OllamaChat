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
        static let kDefaultCompletion = "ModelManager.LocalStore"
    }

    static let shared = APIManager()

    private static var storage: [ChatCompletion] {
        get { UserDefaults.standard.getCodable(forKey: Constants.kLocalStore) ?? [] }
        set { UserDefaults.standard.setCodable(newValue, forKey: Constants.kLocalStore) }
    }
    
    private static var defaultCompletionID: String? {
        get { UserDefaults.standard.value(forKey: Constants.kLocalStore) as? String }
        set { UserDefaults.standard.set(newValue, forKey: Constants.kLocalStore) }
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

    private init() {}

    func loadCompletions() {
        completions = APIManager.storage
    }

    func createCompletion(provider: ModelProvider, name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) throws {
        let completion = ChatCompletion(
            provider: provider,
            name: name,
            endpoint: endpoint,
            apiKey: apiKey,
            configJSONRaw: configJSON
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

    @available(*, deprecated, message: "Use createCompletion(provider:name:endpoint:apiKey:configJSON:) instead")
    func createOpenAICompletion(name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        do {
            try createCompletion(provider: .openai, name: name, endpoint: endpoint, apiKey: apiKey, configJSON: configJSON)
        } catch {
            print("Error creating OpenAI completion: \(error)")
        }
    }
    
    func updateCompletion(at index: Int, name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        guard index >= 0 && index < completions.count else { return }

        completions[index].name = name
        completions[index].endpoint = endpoint
        completions[index].apiKey = apiKey
        completions[index].configJSONRaw = configJSON

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

    func migrateLegacyCompletions() {
        // Migrate old .api completions to .openai for backwards compatibility
        for i in 0..<completions.count {
            if completions[i].provider.rawValue == "api" {
                completions[i].provider = .openai
            }
        }
        APIManager.storage = completions
    }
}
