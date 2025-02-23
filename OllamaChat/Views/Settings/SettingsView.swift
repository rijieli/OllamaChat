//
//  SettingsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

#if os(macOS)
import AVFoundation
import SwiftUI

struct SettingsView: View {

    private enum Tabs: Hashable {
        case general, models, chatOptions
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            ManageModelsView()
                .tabItem {
                    Label("Models", systemImage: "cube")
                }
                .tag(Tabs.models)
            ChatOptionsView()
                .tabItem {
                    Label("Chat Options", systemImage: "plus.message.fill")
                }
                .tag(Tabs.chatOptions)
        }
        .frame(width: 600)
    }
}

struct SettingsSectionHeader: View {
    let title: LocalizedStringKey
    
    init(_ title: LocalizedStringKey) {
        self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
    }
}

#endif
