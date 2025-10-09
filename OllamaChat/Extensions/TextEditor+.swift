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

    @MainActor
    func disableAutoQuotes() -> some View {
        #if os(macOS)
            self.introspect(.textEditor, on: .macOS(.v13, .v14, .v15, .v26)) { nsTextView in
                nsTextView.isAutomaticQuoteSubstitutionEnabled = false
                nsTextView.isAutomaticDashSubstitutionEnabled = false
            }
        #else
        self.introspect(.textEditor, on: .iOS(.v17, .v18, .v26)) { nsTextView in
                nsTextView.autocorrectionType = .no
                nsTextView.autocapitalizationType = .none
            }
        #endif

    }

}
