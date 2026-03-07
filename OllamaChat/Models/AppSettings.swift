//
//  AppSettings.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation

class AppSettings {
    private enum Constants {
        static let defaultChatConfigurationStorageKey = "AppSettings.DefaultChatConfiguration.v1"
    }

    @UserDefaultsBacked(key: "AppSettings.GlobalSystem")
    static var globalSystem = ""

    static var defaultChatConfiguration: ChatConfiguration {
        get {
            let storedConfiguration: ChatConfiguration? = UserDefaults.standard.getCodable(
                forKey: Constants.defaultChatConfigurationStorageKey
            )
            if let storedConfiguration { return storedConfiguration }
            return .defaultValue
        }
        set {
            UserDefaults.standard.setCodable(
                newValue,
                forKey: Constants.defaultChatConfigurationStorageKey
            )
        }
    }

}
