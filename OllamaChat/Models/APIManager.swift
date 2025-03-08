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

    func createOpenAICompletion(name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        let completion = ChatCompletion(
            provider: .api,
            name: name,
            endpoint: endpoint,
            apiKey: apiKey,
            configJSONRaw: configJSON
        )
        completions.append(completion)
        APIManager.storage = completions
        
        if completions.count == 1 {
            defaultCompletion = completion
        }
    }
    
    func updateCompletion(at index: Int, name: String, endpoint: String, apiKey: String? = nil, configJSON: String? = nil) {
        guard index >= 0 && index < completions.count else { return }
        
        completions[index].name = name
        completions[index].endpoint = endpoint
        completions[index].apiKey = apiKey
        completions[index].configJSONRaw = configJSON
        
        APIManager.storage = completions
    }
    
    func deleteCompletion(withName name: String) {
        completions.removeAll(where: { $0.name == name })
        APIManager.storage = completions
    }
}
