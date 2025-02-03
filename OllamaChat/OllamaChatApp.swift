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
                CommandGroup(after: .newItem) {
                    Button(action: {

                        if let currentWindow = NSApp.keyWindow,
                            let windowController = currentWindow.windowController
                        {
                            windowController.newWindowForTab(nil)
                            if let newWindow = NSApp.keyWindow,
                                currentWindow != newWindow
                            {
                                currentWindow.addTabbedWindow(newWindow, ordered: .above)
                            }
                        }
                    }) {
                        Text("New Tab")
                    }
                    .keyboardShortcut("t", modifiers: [.command])
                }
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
