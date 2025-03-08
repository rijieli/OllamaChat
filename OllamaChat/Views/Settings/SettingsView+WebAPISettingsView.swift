//
//  WebAPISettingsVIew.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/2.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct WebAPISettingsView: View {
    @StateObject private var modelManager = APIManager.shared

    @State private var isAddingNewAPI = false
    @State private var editingCompletion: ChatCompletion?
    @State private var apiToDelete: ChatCompletion?
    @State private var showDeleteConfirmation = false

    @State private var newCompletionName = ""
    @State private var newCompletionEndpoint = ""
    @State private var newCompletionApiKey = ""
    @State private var newCompletionConfig = ""

    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionHeader("Web API Connections")
                .maxWidth(alignment: .leading)

            if modelManager.completions.isEmpty {
                Text("No API connections configured.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                List {
                    ForEach(modelManager.completions, id: \.name) { completion in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(completion.name)
                                    .font(.headline)
                                Text(completion.endpoint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                prepareForEditing(completion)
                            }) {
                                Image(systemName: "pencil")
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                apiToDelete = completion
                                showDeleteConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .frame(height: 100)
                .modifier(BorderDecoratedStyleModifier(paddingV: 8))
            }

            Button("Add New API Connection") {
                resetNewCompletionFields()
                isAddingNewAPI = true
            }
            .padding(.top, 8)

            if isAddingNewAPI || editingCompletion != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text(editingCompletion != nil ? "Edit API Connection" : "New API Connection")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Name", text: $newCompletionName)
                        TextField("Endpoint URL", text: $newCompletionEndpoint)
                        SecureField("API Key (optional)", text: $newCompletionApiKey)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Configuration (optional JSON)")
                                .font(.caption)
                            TextEditor(text: $newCompletionConfig)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 100)
                                .border(Color.gray.opacity(0.2))
                        }
                    }

                    HStack {
                        Button("Cancel") {
                            isAddingNewAPI = false
                            editingCompletion = nil
                        }

                        Spacer()

                        Button(editingCompletion != nil ? "Update" : "Create") {
                            if editingCompletion != nil {
                                updateExistingCompletion()
                            } else {
                                createNewCompletion()
                            }
                        }
                        .disabled(newCompletionName.isEmpty || newCompletionEndpoint.isEmpty)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .maxWidth()
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete API Connection"),
                message: Text("Are you sure you want to delete '\(apiToDelete?.name ?? "")'?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let apiToDelete = apiToDelete {
                        deleteCompletion(apiToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    private func createNewCompletion() {
        // Validate URL
        if !isValidURL(newCompletionEndpoint) {
            errorMessage = "Please enter a valid URL"
            showError = true
            return
        }

        // Validate JSON if provided
        if !newCompletionConfig.isEmpty {
            if !isValidJSON(newCompletionConfig) {
                errorMessage = "Configuration is not valid JSON"
                showError = true
                return
            }
        }

        modelManager.createOpenAICompletion(
            name: newCompletionName,
            endpoint: newCompletionEndpoint,
            apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
            configJSON: newCompletionConfig.isEmpty ? nil : newCompletionConfig
        )

        isAddingNewAPI = false
    }

    private func updateExistingCompletion() {
        guard
            let index = modelManager.completions.firstIndex(where: {
                $0.name == editingCompletion?.name
            })
        else {
            return
        }

        // Validate URL
        if !isValidURL(newCompletionEndpoint) {
            errorMessage = "Please enter a valid URL"
            showError = true
            return
        }

        // Validate JSON if provided
        if !newCompletionConfig.isEmpty {
            if !isValidJSON(newCompletionConfig) {
                errorMessage = "Configuration is not valid JSON"
                showError = true
                return
            }
        }

        modelManager.updateCompletion(
            at: index,
            name: newCompletionName,
            endpoint: newCompletionEndpoint,
            apiKey: newCompletionApiKey.isEmpty ? nil : newCompletionApiKey,
            configJSON: newCompletionConfig.isEmpty ? nil : newCompletionConfig
        )

        editingCompletion = nil
    }

    private func deleteCompletion(_ completion: ChatCompletion) {
        modelManager.deleteCompletion(withName: completion.name)
        apiToDelete = nil
    }

    private func prepareForEditing(_ completion: ChatCompletion) {
        newCompletionName = completion.name
        newCompletionEndpoint = completion.endpoint
        newCompletionApiKey = completion.apiKey ?? ""
        newCompletionConfig = completion.configJSONRaw ?? ""
        editingCompletion = completion
    }

    private func resetNewCompletionFields() {
        newCompletionName = ""
        newCompletionEndpoint = ""
        newCompletionApiKey = ""
        newCompletionConfig = ""
    }

    private func isValidURL(_ urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return NSApplication.shared.canOpenURL(url)
        }
        return false
    }

    private func isValidJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }
}
