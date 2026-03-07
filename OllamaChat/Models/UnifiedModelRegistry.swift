//
//  UnifiedModelRegistry.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/09.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI

/// Centralized model fetching and caching for Ollama models.
@MainActor
class UnifiedModelRegistry: ObservableObject {
    static let shared = UnifiedModelRegistry()

    @Published var isLoading = false
    @Published var error: Error?

    private var cachedModels: [String] = []
    private var cachedEndpoint: String?
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes

    private init() {}

    func fetchAllModels() async {
        await fetchModels(force: false)
    }

    func refreshModels() async {
        await fetchModels(force: true)
    }

    func clearCache() {
        cachedModels = []
        cachedEndpoint = nil
        lastFetchTime = nil
    }

    private func fetchModels(force: Bool) async {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let endpoint = APIManager.shared.endpoint

        if !force,
           cachedEndpoint == endpoint,
           let lastFetchTime,
           Date().timeIntervalSince(lastFetchTime) < cacheTimeout,
           !cachedModels.isEmpty {
            APIManager.shared.replaceAvailableModels(cachedModels)
            return
        }

        do {
            log.debug("Fetching Ollama models")
            let modelGroup = try await fetchOllamaModels()
            cachedModels = modelGroup.models.map(\.name)
            cachedEndpoint = endpoint
            lastFetchTime = Date()
        } catch {
            log.error("Failed to fetch Ollama models: \(error)")
            self.error = error
        }
    }
}
