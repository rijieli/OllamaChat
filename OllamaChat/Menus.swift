//
//  Menus.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/17.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI

struct Menus: Commands {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Commands {
        // ToolbarCommands()
        // SidebarCommands()
        
        // Replace the About menu item.
        CommandGroup(after: CommandGroupPlacement.appInfo) {
            Button("Check for updates... ") {
                appDelegate.checkForUpdates()
            }
        }
    }
}
