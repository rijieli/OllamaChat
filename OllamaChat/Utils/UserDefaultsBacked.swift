//
//  UserDefaultsBacked.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation

/// - note: From: https://www.swiftbysundell.com/articles/property-wrappers-in-swift/
@propertyWrapper struct UserDefaultsBacked<Value> {
    let key: String
    var storage: UserDefaults = .standard
    private let defaultValue: Value
    
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey:key) as? Value
            return value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }
        }
    }
    
    init(wrappedValue defaultValue: Value, key: String, storage: UserDefaults = .standard) {
        self.defaultValue = defaultValue
        self.key = key
        self.storage = storage
    }
}

extension UserDefaultsBacked where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(wrappedValue: nil, key: key, storage: storage)
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}

extension UserDefaults {
//    static var vwShared: UserDefaults {
//        let combined = UserDefaults(suiteName: kAppGroupSuiteName)!
//        return combined
//    }
}
