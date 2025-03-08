//
//  SettingsViewModel.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/8.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    
    static let shared = SettingsViewModel()
    
    private init() {}
    
    @Published var selectedTab = SettingsView.SettingsTab.general
    
}
