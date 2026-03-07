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

    var endpoint: String {
        configuration.endpoint
    }

    func updateEndpoint(_ endpoint: String) {
        let normalizedEndpoint = normalizeEndpoint(endpoint)
        guard configuration.endpoint != normalizedEndpoint else { return }
        configuration.endpoint = normalizedEndpoint
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
