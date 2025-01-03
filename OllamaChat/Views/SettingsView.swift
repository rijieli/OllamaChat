//
//  SettingsView.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

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
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("host") private var host = "http://127.0.0.1"
    @AppStorage("port") private var port = "11434"
    @AppStorage("timeoutRequest") private var timeoutRequest = "60"
    @AppStorage("timeoutResource") private var timeoutResource = "604800"

    @State private var voiceGenderPreference = TextSpeechCenter.shared.voiceGenderPreference

    var body: some View {
        Form {
            VStack {
                HStack {
                    TextField("Host IP:", text: $host)
                    TextField("Port:", text: $port)
                        .onChange(of: port) { _ in
                            let filtered = port.filter { "0123456789".contains($0) }
                            if filtered != port {
                                self.port = filtered
                            }
                        }
                }
                TextField("Request Timeout (in sec. Default 60):", text: $timeoutRequest)
                    .onChange(of: timeoutRequest) { _ in
                        let filtered = timeoutRequest.filter { "0123456789".contains($0) }
                        if filtered != timeoutRequest {
                            self.timeoutRequest = filtered
                        }
                    }

                TextField("Resources Timeout (in sec. Default: 604800):", text: $timeoutResource)
                    .onChange(of: timeoutResource) { _ in
                        let filtered = timeoutResource.filter { "0123456789".contains($0) }
                        if filtered != timeoutResource {
                            self.timeoutResource = filtered
                        }
                    }
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
            }
        }
        .padding()
        .frame(width: 550)
    }
}
