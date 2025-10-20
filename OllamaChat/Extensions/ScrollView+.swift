//
//  ScrollView+.swift
//  OllamaChat
//
//  Created by Roger on 2025/10/20.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

extension ScrollView {
    
    func ifScrollClipDisabled(_ value: Bool) -> some View {
        if #available(macOS 14, *) {
            return self.scrollClipDisabled(value)
        } else {
            return self
        }
    }
    
}
