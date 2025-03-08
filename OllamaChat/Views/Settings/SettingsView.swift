//
//  SettingsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

#if os(macOS)
import AVFoundation
import SwiftUI
import AppKit

struct SettingsView: View {

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general
        case models
        case chatOptions
        case webAPI
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .general: "General"
            case .models: "Models"
            case .chatOptions: "Chat Options"
            case .webAPI: "Web API"
            }
        }
        var sfSymbol: String {
            switch self {
            case .general: "gearshape"
            case .models: "cube.box"
            case .chatOptions: "text.bubble"
            case .webAPI: "network"
            }
        }
        
        static var tabs: [SettingsTab] {
            #if DEBUG
            return allCases
            #else
            return [.general, .models, .chatOptions]
            #endif
        }
    }

    @Environment(\.isDarkMode) var isDarkMode

    @StateObject var viewModel = SettingsViewModel.shared

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(.appicon100)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .padding(.vertical, 8)
                    Text(verbatim: "Ollama Chat")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.primary)
                .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(SettingsTab.tabs) { tab in
                            let selected = viewModel.selectedTab == tab
                            Button {
                                if !selected {
                                    viewModel.selectedTab = tab
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: tab.sfSymbol)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20)
                                        .fontWeight(.semibold)
                                    
                                    Text(tab.title)
                                        .maxWidth(alignment: .leading)
                                }
                                .font(.system(size: 13))
                                .frame(height: 32)
                                .padding(.horizontal, 8)
                                .background {
                                    if selected {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor)
                                    }
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(
                                selected ? .white : isDarkMode ? Color.white : Color.black
                            )
                        }
                    }
                    .padding(8)
                }
                .maxFrame()
                
                ZStack {
                    HStack(spacing: 4) {
                        Text(verbatim: "IdeasForm")
                            .font(.system(size: 10, weight: .semibold))
                        Text("v\(AppInfo.version) (\(AppInfo.build))")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(height: 40)
            }
            .visualEffect(material: .fullScreenUI)
            .frame(width: 215)
            .ignoresSafeArea()

            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        switch viewModel.selectedTab {
                        case .general:
                            GeneralSettingsView()
                        case .models:
                            ManageModelsView()
                        case .chatOptions:
                            ChatOptionsView()
                        case .webAPI:
                            WebAPISettingsView()
                        }
                    }
                    .maxFrame()
                    .padding(.horizontal, 16)
                }
                .id(viewModel.selectedTab)
            }
            .maxFrame()
            .background(.background)
        }
        .frame(minWidth: 715, maxWidth: 715, minHeight: 540, maxHeight: .infinity)
        .introspect(.window, on: .macOS(.v13, .v14, .v15)) { nsWindow in
            nsWindow.titlebarAppearsTransparent = true
            nsWindow.titleVisibility = .hidden
        }
    }
}

struct SettingsSectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    
    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}

#endif
