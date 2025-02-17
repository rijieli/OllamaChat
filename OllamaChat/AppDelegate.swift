//
//  AppDelegate.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation
#if os(macOS)
import AppKit
import Sparkle
#else
import UIKit
#endif
import SwiftUI

class AppDelegate: NSObject {
    #if os(macOS)
    var updaterController: SPUStandardUpdaterController?
    #endif
}

#if os(macOS)
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
#else
extension AppDelegate: UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        CoreDataStack.shared.saveContext()
    }
}
#endif
