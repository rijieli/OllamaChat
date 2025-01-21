//
//  OllamaChatApp.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 07.10.23.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI

@main
struct OllamaChatApp: App {

        #if os(macOS)
            @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        #else
            @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        #endif
    

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environment(\.managedObjectContext, CoreDataStack.shared.context)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button(action: {
                    #if os(macOS)
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
                    #endif
                }) {
                    Text("New Tab")
                }
                .keyboardShortcut("t", modifiers: [.command])
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
