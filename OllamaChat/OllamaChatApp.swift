//
//  OllamaChatApp.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 07.10.23.
//

import SwiftUI

@main
struct OllamaChatApp: App {
    var body: some Scene {
        let mainWindow = WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
          }
          #if os(macOS)      
          Settings {
            SettingsView()
          }
          mainWindow.commands {
            CommandGroup(after: .newItem) {
              Button(action: {
                if let currentWindow = NSApp.keyWindow,
                  let windowController = currentWindow.windowController {
                  windowController.newWindowForTab(nil)
                  if let newWindow = NSApp.keyWindow,
                    currentWindow != newWindow {
                      currentWindow.addTabbedWindow(newWindow, ordered: .above)
                    }
                }
              }) {
                Text("New Tab")
              }
              .keyboardShortcut("t", modifiers: [.command])
            }
          }
          #else
          mainWindow
          #endif
//        WindowGroup {
//            ContentView()
//        }
    }
}
