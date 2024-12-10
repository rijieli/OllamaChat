//
//  Tags.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Foundation

struct ModelGroup: Decodable, Hashable {
    let models: [LanguageModel]
}

struct LanguageModel: Decodable, Hashable {
    let name: String
    let modifiedAt: String
    let size: Double
    let digest: String
    
    var modelInfo: (provider: String?, model: String, scale: String?) {
        var model = name
        let provider: String?
        if let index = model.firstIndex(of: "/") {
            provider = String(model[..<index])
            model = String(model[(model.index(after: index))...])
        } else {
            provider = nil
        }
        
        let scale: String?
        if let index = model.lastIndex(of: ":") {
            scale = String(model[(model.index(after: index))...]).uppercased()
            model = String(model[..<index])
        } else {
            scale = nil
        }
        return (
            provider: provider,
            model: model.capitalized,
            scale: scale
        )
    }
}
