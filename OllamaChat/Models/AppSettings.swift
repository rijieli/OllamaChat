//
//  AppSettings.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/15.
//

import Foundation

class AppSettings {

    @UserDefaultsBacked(key: "AppSettings.GlobalSystem")
    static var globalSystem = ""

}
