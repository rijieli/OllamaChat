//
//  SettingsiOSView.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

#if os(iOS)
import SwiftUI
import UIKit

struct SettingsiOSView: View {

    @Environment(\.dismiss) var dismiss

    @State var localIP: NetworkAddresses? = nil

    @StateObject var chatViewModel: ChatViewModel = .shared
    @StateObject var apiManager: APIManager = .shared
    
    @State private var globalSystemPrompt = AppSettings.globalSystem

    private var defaultModelBinding: Binding<String> {
        Binding(
            get: { apiManager.selectedModel },
            set: { apiManager.updateSelectedModel($0) }
        )
    }

    private var availableModelNames: [String] {
        let liveModelNames = chatViewModel.tags.models.map(\.name)
        let modelNames = liveModelNames.isEmpty ? apiManager.configuration.models : liveModelNames
        guard !apiManager.selectedModel.isEmpty,
              !modelNames.contains(apiManager.selectedModel)
        else {
            return modelNames
        }

        return [apiManager.selectedModel] + modelNames
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ollama Service Config")
                                .font(.headline)
                            NumericTextField(title: "Host IP:", text: $chatViewModel.host)
                            
                            if let localIP {
                                VStack(spacing: 2) {
                                    Group {
                                        Text("Current Local IPv4:")
                                        Text("\(localIP.ipv4 ?? "nil")")
                                        Text("Current Local IPv6:")
                                        Text("\(localIP.ipv6 ?? "nil")")
                                    }
                                    .maxWidth(alignment: .leading)
                                    .lineLimit(1)
                                }
                            }
                            
                            NumericTextField(title: "Port:", text: $chatViewModel.port)
                            NumericTextField(
                                title: "Request Timeout",
                                text: $chatViewModel.timeoutRequest
                            )
                            NumericTextField(
                                title: "Resources Timeout",
                                text: $chatViewModel.timeoutResource
                            )
                        }
                        .textFieldStyle(.roundedBorder)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.endEditing()
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Chat Model")
                                .font(.headline)
                            Text("Changing the model inside a chat does not change this default.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if availableModelNames.isEmpty {
                                Text("Refresh the model list to choose a default model for new chats.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Default Model", selection: defaultModelBinding) {
                                    ForEach(availableModelNames, id: \.self) { modelName in
                                        Text(defaultModelLabel(for: modelName))
                                            .tag(modelName)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Global System Prompt:")
                                        .font(.headline)
                                    Text("Used only when creating a new chat.")
                                        .font(.footnote)
                                }
                                Spacer()
                                Button("Save") {
                                    AppSettings.globalSystem = globalSystemPrompt
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            TextEditor(text: $globalSystemPrompt)
                                .disableAutoQuotes()
                                .font(.body)
                                .frame(height: 100)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                                )
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                localIP = UIApplication.shared.getNetworkAddresses()
            }
        }
    }

    private func defaultModelLabel(for modelName: String) -> String {
        let knownModelNames = Set(chatViewModel.tags.models.map(\.name))
            .union(apiManager.configuration.models)
        guard !knownModelNames.contains(modelName) else {
            return modelName
        }

        return "\(modelName) (Unavailable)"
    }

}

private struct NumericTextField: View {
    let title: String
    @Binding var text: String
    var allowedCharacters: String = "0123456789"

    var body: some View {
        LabeledContent {
            TextField(title, text: $text)
                .keyboardType(.asciiCapable)
        } label: {
            Text(title)
        }
    }
}
#endif
