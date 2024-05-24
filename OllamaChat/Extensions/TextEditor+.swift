//
//  TextEditor+.swift
//  OllamaChat
//
//  Created by Roger on 2024/5/24.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIIntrospect

extension TextEditor {
    
    func disableAutoQuotes() -> some View {
        self.introspect(.textEditor, on: .macOS(.v14, .v13)) { nsTextView in
            nsTextView.isAutomaticQuoteSubstitutionEnabled = false
            nsTextView.isAutomaticDashSubstitutionEnabled = false
        }
    }
    
}
