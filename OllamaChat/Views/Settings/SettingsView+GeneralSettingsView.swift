//
//  SettingsView+GeneralSettingsView.swift
//  OllamaChat
//
//  Created by Roger on 2025/12/9.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import AVFoundation
import SwiftUI

extension SettingsView {
    
    struct GeneralSettingsView: View {
        @State private var voiceGenderPreference = TextSpeechCenter.shared.voiceGenderPreference
        @State private var globalSystemPrompt = AppSettings.globalSystem
        var body: some View {
            VStack(alignment: .leading) {
                SettingsSectionHeader("General", subtitle: "General settings for the app.")
                VStack(alignment: .leading) {
                    HStack {
                        SettingsSectionHeader(
                            "Global System Prompt:",
                            subtitle: "Automatic apply to each chat."
                        )
                        Spacer(minLength: 0)
                        Button("Save") {
                            AppSettings.globalSystem = globalSystemPrompt
                        }
                    }
                    TextEditor(text: $globalSystemPrompt)
                        .disableAutoQuotes()
                        .font(.body)
                        .frame(height: 100)
                        .modifier(BorderDecoratedStyleModifier())
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
                Spacer(minLength: 0)
            }
            .padding(24)
        }
        
    }
    
}
