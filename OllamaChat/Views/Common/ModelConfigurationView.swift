//
//  ModelConfigurationView.swift
//  OllamaChat
//
//  Created by Roger on 2026/3/7.
//  Copyright © 2026 IdeasForm. All rights reserved.
//
import SwiftUI

struct ModelConfigurationView: View {
    private enum EditorTab: String, CaseIterable, Identifiable {
        case systemPrompt
        case configuration

        var id: Self { self }

        var title: LocalizedStringKey {
            switch self {
            case .systemPrompt:
                "System Prompt"
            case .configuration:
                "Configuration"
            }
        }
    }

    @ObservedObject var viewModel = ChatViewModel.shared

    @State private var selectedTab: EditorTab = .systemPrompt
    @State var systemPrompt: String = ""

    @FocusState private var isPopupFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedTab) {
                ForEach(EditorTab.allCases) { tab in
                    Text(tab.title)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTab {
                case .systemPrompt:
                    systemPromptTab
                case .configuration:
                    configurationTab
                }
            }
            .maxFrame()

            footerView
        }
        .padding(.horizontal, 12)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(width: 500, height: 600)
        .task {
            systemPrompt =
                viewModel.messages.first(where: { $0.role == .system })?.content ?? ""
            isPopupFocused = true
        }
        .onChange(of: selectedTab) { newTab in
            isPopupFocused = newTab == .systemPrompt
        }
    }

    private var systemPromptTab: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("System Prompt")
                    .font(.system(size: 18, weight: .bold))
                    .maxWidth(alignment: .leading)
                Text(
                    "This text will be sent at the start of the chat, which is also referred to as the Role System."
                )
                .font(.system(size: 12))
                .maxWidth(alignment: .leading)
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 8)

            TextEditor(text: $systemPrompt)
                .disableAutoQuotes()
                .scrollContentBackground(.hidden)
                .font(.body)
                .onSubmit {
                    updateSystem()
                }
                .focused(self.$isPopupFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8.variable(os26: 16))
                        .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                )
                .background()
        }
        .maxFrame(alignment: .top)
    }

    private var configurationTab: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ModelEditingView(chatConfiguration: $viewModel.chatConfiguration)
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var footerView: some View {
        HStack {
            Button(selectedTab == .systemPrompt ? "Cancel" : "Close") {
                dismiss()
            }

            if selectedTab == .systemPrompt {
                Button("Save") {
                    updateSystem()
                }
            }
        }
        .frame(height: 32)
        .maxWidth(alignment: .trailing)
    }

    private func dismiss() {
        isPopupFocused = false
        viewModel.showModelConfiguration = false
    }

    func updateSystem() {
        viewModel.updateSystem(.init(role: .system, content: systemPrompt))
    }
}
