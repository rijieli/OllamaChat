//
//  OllamaChatApp.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 07.10.23.
//

import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

@main
struct OllamaChatApp: App {

    #if os(macOS)
        @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
            WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, CoreDataStack.shared.context)
                #if DEBUG
                    .environment(\.locale, .enUS)
                #endif
            }
            .commands {
                Menus()
            }
            Settings {
                SettingsView()
            }
        #else
            WindowGroup {
                ContentView()
                    .environment(\.managedObjectContext, CoreDataStack.shared.context)
            }
        #endif
    }
}
