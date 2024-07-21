//
//  AppDelegate.swift
//  OllamaChat
//
//  Created by Roger on 2024/7/21.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    
    func applicationWillTerminate(_ notification: Notification) {
        CoreDataStack.shared.saveContext()
    }
    
}
