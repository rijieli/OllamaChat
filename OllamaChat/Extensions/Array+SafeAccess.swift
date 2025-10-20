//
//  Array+SafeAccess.swift
//  OllamaChat
//
//  Created by Roger on 2025/3/1.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}