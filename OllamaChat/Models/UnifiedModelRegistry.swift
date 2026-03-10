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
    // Assumes the app talks to one stable Ollama endpoint, so model name is sufficient as the cache key.
    private var showModelCache: [String: [OllamaShowModelCacheVariant: OllamaShowModelResponse]] = [:]

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
        error = nil
        showModelCache = [:]
    }

    func cachedThinkSupport(for model: String) -> OllamaThinkSupport {
        showModelCache[model]?[.standard]?.thinkSupport ?? .unknown
    }

    func fetchShowModelDetails(
        for model: String,
        timeout: Double? = nil,
        verbose: Bool? = nil,
        useCache: Bool = true
    ) async throws -> OllamaShowModelResponse {
        let cacheVariant = OllamaShowModelCacheVariant(verbose: verbose)

        if useCache, let cachedResponse = showModelCache[model]?[cacheVariant] {
            return cachedResponse
        }

        let endpoint = apiEndpoint + "show"

        guard let url = URL(string: endpoint) else {
            let invalidURLError = NetError.invalidURL(error: nil)
            log.error("Failed to fetch show model details: \(invalidURLError)")
            throw invalidURLError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OllamaShowModelRequest(model: model, verbose: verbose)
        )

        let data: Data
        let response: URLResponse

        do {
            log.debug("Fetching show model details for model: \(model)")
            (data, response) = try await makeSession(timeout: timeout).data(for: request)
        } catch {
            let unreachableError = NetError.unreachable(error: error)
            log.error("Failed to fetch show model details: \(unreachableError)")
            throw unreachableError
        }

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            let invalidResponseError = NetError.invalidResponse(error: nil)
            log.error("Failed to fetch show model details: \(invalidResponseError)")
            throw invalidResponseError
        }

        do {
            let decoded = try JSONDecoder().decode(OllamaShowModelResponse.self, from: data)
            var cachedVariants = showModelCache[model] ?? [:]
            cachedVariants[cacheVariant] = decoded
            showModelCache[model] = cachedVariants
            objectWillChange.send()
            return decoded
        } catch {
            let invalidDataError = NetError.invalidData(error: error)
            log.error("Failed to decode show model details: \(invalidDataError)")
            throw invalidDataError
        }
    }

    func fetchThinkSupport(for model: String, timeout: Double? = nil) async throws -> OllamaThinkSupport {
        let showModelDetails = try await fetchShowModelDetails(for: model, timeout: timeout)
        return showModelDetails.thinkSupport
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

        do {
            log.debug("Fetching Ollama models")
            (data, response) = try await makeSession(timeout: timeout).data(from: url)
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
        let modifiedAtByModel = Dictionary(uniqueKeysWithValues: models.map { ($0.name, $0.modifiedAt) })
        showModelCache = showModelCache.reduce(into: [:]) { result, entry in
            guard let latestModifiedAt = modifiedAtByModel[entry.key] else { return }

            let validResponses = entry.value.filter { _, response in
                guard let cachedModifiedAt = response.modifiedAt else { return false }
                return cachedModifiedAt == latestModifiedAt
            }

            if !validResponses.isEmpty {
                result[entry.key] = validResponses
            }
        }

        if models.isEmpty {
            ChatViewModel.shared.errorModel = noModelsError(error: nil)
            return
        }

        ChatViewModel.shared.clearError()
    }

    private func makeSession(timeout: Double? = nil) -> URLSession {
        let timeoutRequest = Double(ChatViewModel.shared.timeoutRequest) ?? 60
        let timeoutResource = Double(ChatViewModel.shared.timeoutResource) ?? 604800

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout ?? timeoutRequest
        sessionConfig.timeoutIntervalForResource = timeoutResource
        return URLSession(configuration: sessionConfig)
    }
}
