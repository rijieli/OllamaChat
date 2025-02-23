//
//  SettingsLabeledContentStyle.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/23.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct SettingsLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.label
                .frame(maxWidth: 200, alignment: .leading)
            configuration.content
                .maxWidth()
        }
    }
}

extension LabeledContentStyle where Self == SettingsLabeledContentStyle {
    static var settings: SettingsLabeledContentStyle { SettingsLabeledContentStyle() }
}
