//
//  ChatCompletion.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

protocol ChatCompletionAbility {
    func send(messages: [ChatMessage]) async
    func cancel() async
}

class ModelManager: ObservableObject {
    enum Constants {
        static let kLocalStore = "ModelManager.LocalStore"
    }

    static let shared = ModelManager()

    private static var storage: [ChatCompletion] {
        get { UserDefaults.standard.getCodable(forKey: Constants.kLocalStore) ?? [] }
        set { UserDefaults.standard.setCodable(newValue, forKey: Constants.kLocalStore) }
    }

    @Published var completions: [ChatCompletion] = ModelManager.storage

    private init() {}

    func loadCompletions() {
        completions = ModelManager.storage
    }

    func createOpenAICompletion(name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        let completion = ChatCompletion(
            provider: .api,
            name: name,
            endpoint: endpoint,
            apiKey: apiKey,
            configJSONRaw: configJSON
        )
        completions.append(completion)
        ModelManager.storage = completions
    }
    
    func updateCompletion(at index: Int, name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        guard index >= 0 && index < completions.count else { return }
        
        completions[index].name = name
        completions[index].endpoint = endpoint
        completions[index].apiKey = apiKey
        completions[index].configJSONRaw = configJSON
        
        ModelManager.storage = completions
    }
    
    func deleteCompletion(withName name: String) {
        completions.removeAll(where: { $0.name == name })
        ModelManager.storage = completions
    }
}

enum ModelProvider: String, Codable {
    case ollama
    case api
}

struct ChatCompletion: Codable {
    var provider: ModelProvider
    var name: String
    var endpoint: String
    var apiKey: String?
    var configJSONRaw: String?
}
