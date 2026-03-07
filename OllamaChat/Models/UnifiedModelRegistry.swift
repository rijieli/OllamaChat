//
//  UnifiedModelRegistry.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI

/// Centralized model fetching and storage for Ollama models.
@MainActor
class UnifiedModelRegistry: ObservableObject {
    static let shared = UnifiedModelRegistry()

    @Published var isLoading = false
    @Published var error: Error?
    @Published private(set) var models: [OllamaLanguageModel] = []
    @Published private(set) var hasResolvedModels = false

    private init() {}

    var apiEndpoint: String {
        APIManager.shared.endpoint + "/api/"
    }

    func fetchAllModels() async {
        do {
            _ = try await fetchOllamaModels()
        } catch {
            // `error` is already set by `fetchOllamaModels()`.
        }
    }

    func refreshModels() async {
        await fetchAllModels()
    }

    func invalidateModels() {
        models = []
        hasResolvedModels = false
        error = nil
    }

    @discardableResult
    func fetchOllamaModels(timeout: Double? = nil) async throws -> [OllamaLanguageModel] {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let endpoint = apiEndpoint + "tags"

        guard let url = URL(string: endpoint) else {
            let invalidURLError = NetError.invalidURL(error: nil)
            log.error("Failed to fetch Ollama models: \(invalidURLError)")
            error = invalidURLError
            throw invalidURLError
        }

        let data: Data
        let response: URLResponse

        let timeoutRequest = ChatViewModel.shared.timeoutRequest
        let timeoutResource = ChatViewModel.shared.timeoutResource

        do {
            log.debug("Fetching Ollama models")
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = timeout ?? Double(timeoutRequest) ?? 60
            sessionConfig.timeoutIntervalForResource = Double(timeoutResource) ?? 604800
            (data, response) = try await URLSession(configuration: sessionConfig).data(from: url)
        } catch {
            let unreachableError = NetError.unreachable(error: error)
            log.error("Failed to fetch Ollama models: \(unreachableError)")
            self.error = unreachableError
            throw unreachableError
        }

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let invalidResponseError = NetError.invalidResponse(error: nil)
            log.error("Failed to fetch Ollama models: \(invalidResponseError)")
            error = invalidResponseError
            throw invalidResponseError
        }

        let decoder = JSONDecoder()

        do {
            let decoded = try decoder.decode(OllamaModelGroup.self, from: data)
            applyModels(decoded.models)
            return decoded.models
        } catch {
            let invalidDataError = NetError.invalidData(error: error)
            log.error("Failed to fetch Ollama models: \(invalidDataError)")
            self.error = invalidDataError
            throw invalidDataError
        }
    }

    private func applyModels(_ models: [OllamaLanguageModel]) {
        self.models = models
        hasResolvedModels = true

        let modelNames = models.map(\.name)
        APIManager.shared.replaceAvailableModels(modelNames)

        if models.isEmpty {
            ChatViewModel.shared.errorModel = noModelsError(error: nil)
            return
        }

        APIManager.shared.updateMetadata(
            ModelMetadata(source: "ollama")
        )
        ChatViewModel.shared.clearError()
    }
}
