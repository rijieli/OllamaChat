//
//  SettingsSectionHeader.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/8.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

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
                    .padding(.top, 1)
            }
        }
    }
}
