//
//  SettingsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//
import AppKit
import SwiftUI

struct SettingsView: View {

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general
        case ollama
        case models

        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .ollama: "Ollama"
            case .models: "Models"
            case .general: "General"
            }
        }
        var sfSymbol: String {
            switch self {
            case .ollama: "server.rack"
            case .general: "gearshape"
            case .models: "cube"
            }
        }
    }

    enum OllamaSubTab: String, CaseIterable, Identifiable {
        case general
        case chatOptions

        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .general: "General"
            case .chatOptions: "Chat Options"
            }
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
                        .frame(width: 38, height: 38)
                        .padding(.vertical, 8)
                    Text(verbatim: "Ollama Chat")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.primary)
                .padding(.top, 24)
                .maxWidth(alignment: .leading)
                .padding(.leading, 16)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(SettingsTab.allCases) { tab in
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
            .visualEffect(material: .sidebar)
            .frame(width: 215)
            .ignoresSafeArea()
            .overlay(alignment: .trailing) {
                Color.ocDividerColor
                    .frame(width: 0.5)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                switch viewModel.selectedTab {
                case .ollama:
                    OllamaSettingsView()
                case .models:
                    ManageModelsView()
                case .general:
                    GeneralSettingsView()
                }
            }
            .maxFrame()
            .background(.background)
            .ignoresSafeArea()
        }
        .frame(minWidth: 715, maxWidth: 715, minHeight: 540, maxHeight: .infinity)
        .introspect(.window, on: .macOS(.v13, .v14, .v15, .v26)) { nsWindow in
            nsWindow.titlebarAppearsTransparent = true
            nsWindow.titleVisibility = .hidden
        }
    }
}
