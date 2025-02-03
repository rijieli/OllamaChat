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
        case general, models
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
        }
        .frame(width: 600)
    }
}

struct GeneralSettingsView: View {
    
    @ObservedObject var chatViewModel = ChatViewModel.shared
    
    var host: String { chatViewModel.host }
    var port: String { chatViewModel.port }
    var timeoutRequest: String { chatViewModel.timeoutRequest }
    var timeoutResource: String { chatViewModel.timeoutResource }

    @State private var voiceGenderPreference = TextSpeechCenter.shared.voiceGenderPreference

    var body: some View {
        Form {
            VStack {
                HStack {
                    TextField("Host IP:", text: $chatViewModel.host)
                    TextField("Port:", text: $chatViewModel.port)
                        .onChange(of: port) { _ in
                            let filtered = port.filter { "0123456789".contains($0) }
                            if filtered != port {
                                chatViewModel.port = filtered
                            }
                        }
                }
                TextField("Request Timeout (in sec. Default 60):", text: $chatViewModel.timeoutRequest)
                    .onChange(of: timeoutRequest) { _ in
                        let filtered = timeoutRequest.filter { "0123456789".contains($0) }
                        if filtered != timeoutRequest {
                            chatViewModel.timeoutRequest = filtered
                        }
                    }

                TextField("Resources Timeout (in sec. Default: 604800):", text: $chatViewModel.timeoutResource)
                    .onChange(of: timeoutResource) { _ in
                        let filtered = timeoutResource.filter { "0123456789".contains($0) }
                        if filtered != timeoutResource {
                            chatViewModel.timeoutResource = filtered
                        }
                    }
                #if DEBUG
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
                #endif
            }
        }
        .padding()
    }
}
#endif
