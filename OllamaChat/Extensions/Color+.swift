//
//  Color+.swift
//  OllamaChat
//
//  Created by Roger on 2024/2/22.
//

import Foundation
import Hue
import SwiftUI

extension Color {

    init(hex: String) {
        #if os(macOS)
        self.init(nsColor: .init(hex: hex))
        #else
        self.init(uiColor: .init(hex: hex))
        #endif
    }

}
