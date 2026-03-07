//
//  APIManager.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/7.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

class APIManager: ObservableObject {
    enum Constants {
        static let kOllamaConfiguration = "APIManager.OllamaConfiguration.v1"
    }

    static let shared = APIManager()

    private static var storage: OllamaConfiguration {
        get { UserDefaults.standard.getCodable(forKey: Constants.kOllamaConfiguration) ?? .default }
        set { UserDefaults.standard.setCodable(newValue, forKey: Constants.kOllamaConfiguration) }
    }

    @Published private(set) var configuration: OllamaConfiguration {
        didSet {
            APIManager.storage = configuration
        }
    }

    private init() {
        let storedConfiguration = APIManager.storage
        if storedConfiguration.isValid {
            configuration = storedConfiguration
        } else {
            assert(storedConfiguration.isValid, "Invalid stored Ollama configuration.")
            configuration = .default
            APIManager.storage = configuration
        }
    }

    var selectedModel: String {
        configuration.selectedModel
    }

    var endpoint: String {
        configuration.endpoint
    }

    func updateEndpoint(_ endpoint: String) {
        let normalizedEndpoint = normalizeEndpoint(endpoint)
        guard configuration.endpoint != normalizedEndpoint else { return }
        configuration.endpoint = normalizedEndpoint
    }

    func updateSelectedModel(_ selectedModel: String) {
        guard configuration.selectedModel != selectedModel else { return }
        configuration.selectedModel = selectedModel
    }

    func replaceAvailableModels(_ models: [String]) {
        configuration.models = models

        if configuration.selectedModel.isEmpty, let fallbackModel = models.first {
            assert(false, "Falling back to the first available Ollama model.")
            configuration.selectedModel = fallbackModel
        }
    }

    func updateMetadata(_ metadata: ModelMetadata) {
        configuration.metadata = metadata
    }

    func updateLastUsed() {
        configuration.lastUsed = Date()
    }

    private func normalizeEndpoint(_ endpoint: String) -> String {
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmedEndpoint) else {
            return trimmedEndpoint
        }

        components.path = ""
        components.query = nil
        components.fragment = nil

        let normalizedEndpoint = components.url?.absoluteString ?? trimmedEndpoint
        return normalizedEndpoint.hasSuffix("/")
            ? String(normalizedEndpoint.dropLast())
            : normalizedEndpoint
    }
}
