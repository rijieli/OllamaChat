//
//  AppDelegate.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation
import AppKit
import Sparkle

class AppDelegate: NSObject {
    var updaterController: SPUStandardUpdaterController?
    
    @objc func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        CoreDataStack.shared.saveContext()
    }
}
