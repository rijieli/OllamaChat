//
//  GeneralSettingsView.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/23.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

#if os(macOS)
import SwiftUI
import AVFoundation

struct GeneralSettingsView: View {

    @ObservedObject var chatViewModel = ChatViewModel.shared

    var host: String { chatViewModel.host }
    var port: String { chatViewModel.port }
    var timeoutRequest: String { chatViewModel.timeoutRequest }
    var timeoutResource: String { chatViewModel.timeoutResource }

    @State private var voiceGenderPreference = TextSpeechCenter.shared.voiceGenderPreference
    @State private var isTestingConnection = false
    @State private var testResult: (success: Bool, message: String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionHeader("Ollama Service")
            HStack {
                LabeledContent("Host:") {
                    TextField("Host:", text: $chatViewModel.host)
                }
                LabeledContent("Port(optional):") {
                    TextField("Port(optional):", text: $chatViewModel.port)
                        .onChange(of: port) { _ in
                            let filtered = port.filter { "0123456789".contains($0) }
                            if filtered != port {
                                chatViewModel.port = filtered
                            }
                        }
                }
            }

            LabeledContent("Request Timeout (Default 60s):") {
                TextField(
                    "Request Timeout (Default 60s):",
                    text: $chatViewModel.timeoutRequest
                )
                .onChange(of: timeoutRequest) { _ in
                    let filtered = timeoutRequest.filter { "0123456789".contains($0) }
                    if filtered != timeoutRequest {
                        chatViewModel.timeoutRequest = filtered
                    }
                }
            }
            .labeledContentStyle(.settings)

            HStack(spacing: 8) {
                Button(action: testConnection) {
                    Text("Test Connection")
                }
                .disabled(isTestingConnection)

                if isTestingConnection {
                    ProgressView()
                        .controlSize(.small)
                } else if let result = testResult {
                    HStack(spacing: 4) {
                        Image(
                            systemName: result.success
                                ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(result.success ? .green : .red)
                        Text(result.message)
                            .lineLimit(1)
                            .foregroundColor(result.success ? .green : .red)
                    }
                }
            }
            
            if let result = testResult, result.success == false {
                Text(helperText)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .maxWidth(alignment: .leading)
            }

            #if DEBUG
            CommonSeparator(4)
            SettingsSectionHeader("Speech Settings")
            Picker("Voice Gender:", selection: $voiceGenderPreference) {
                ForEach(
                    [AVSpeechSynthesisVoiceGender.unspecified, .female, .male],
                    id: \.rawValue
                ) { model in
                    Text(model.title).tag(model)
                }
            }
            .onChange(of: voiceGenderPreference) { newValue in
                TextSpeechCenter.shared.voiceGenderPreference = newValue
            }
            .labeledContentStyle(.settings)
            #endif
        }
        .maxWidth()
        .padding(16)
    }

    private func testConnection() {
        isTestingConnection = true
        testResult = nil

        Task {
            do {
                _ = try await getLocalModels(timeout: 5)
                DispatchQueue.main.async {
                    self.testResult = (
                        true, "Connected: \(APIEndPoint)"
                    )
                    self.isTestingConnection = false
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.testResult = (false, error.localizedDescription)
                    self.isTestingConnection = false
                }
            }
        }
    }
}
#endif


fileprivate let helperText: LocalizedStringKey = """
If you are using a web URL as the host, you can try removing the port. If you are running Ollama locally, try using http://127.0.0.1 and set the port to 11434.
"""
