//
//  UserDefaults+.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

extension UserDefaults {
    func setCodable<T: Codable>(_ codable: T, forKey key: String) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(codable)
            set(data, forKey: key)
        } catch {
            log.error("Local storage error: \(error)")
        }
    }

    func getCodable<T: Codable>(forKey key: String) -> T? {
        guard let data = data(forKey: key) else {
            return nil
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            log.error("Error decoding object for key \(key): \(error)")
            return nil
        }
    }
}
