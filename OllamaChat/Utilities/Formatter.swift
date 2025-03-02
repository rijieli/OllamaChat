//
//  Formatter.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/3.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Foundation

let fileSizeFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter
}()
