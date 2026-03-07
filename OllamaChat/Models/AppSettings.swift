//
//  AppSettings.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation

class AppSettings {
    private enum Constants {
        static let defaultChatOptionsStorageKey = "AppSettings.DefaultChatOptions.v1"
    }

    @UserDefaultsBacked(key: "AppSettings.GlobalSystem")
    static var globalSystem = ""

    static var defaultChatOptions: ChatOptions {
        get {
            let storedOptions: ChatOptions? = UserDefaults.standard.getCodable(
                forKey: Constants.defaultChatOptionsStorageKey
            )
            if let storedOptions {
                return storedOptions
            }

            let storedValue = UserDefaults.standard.object(
                forKey: Constants.defaultChatOptionsStorageKey
            )
            assert(
                storedValue == nil,
                "Stored default chat options are invalid; using built-in defaults."
            )
            return .defaultValue
        }
        set {
            UserDefaults.standard.setCodable(
                newValue,
                forKey: Constants.defaultChatOptionsStorageKey
            )
        }
    }

}
