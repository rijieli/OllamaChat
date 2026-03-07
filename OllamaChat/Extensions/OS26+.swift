//
//  OS26+.swift
//  OllamaChat
//
//  Created by Roger on 2026/3/7.
//  Copyright © 2026 IdeasForm. All rights reserved.
//

import Foundation
import SwiftUI

extension Numeric {
    func variable(os26 higher: Self) -> Self {
        if #available(macOS 26, *) { return higher }
        return self
    }
}

extension Color {
    func variable(os26 higher: Self) -> Self {
        if #available(macOS 26, *) { return higher }
        return self
    }
}
