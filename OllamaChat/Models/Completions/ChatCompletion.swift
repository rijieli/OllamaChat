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

    func createOpenAICompletion(name: String, endpoint: String) {
        let completion = ChatCompletion(
            provider: .api,
            name: name,
            endpoint: endpoint,
            apiKey: nil,
            configJSONRaw: nil
        )
        completions.append(completion)
        ModelManager.storage = completions
    }

}

enum ModelProvider: String, Codable {
    case ollama
    case api
}

struct ChatCompletion: Codable {
    let provider: ModelProvider
    let name: String
    let endpoint: String
    let apiKey: String?
    let configJSONRaw: String?
}
