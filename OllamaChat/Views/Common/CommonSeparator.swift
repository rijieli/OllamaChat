//
//  CommonSeparator.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/23.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

struct CommonSeparator: View {

    let height: CGFloat
    let alignment: Alignment

    /// The line height is always 0.5, parameter height is reserved height
    init(_ height: CGFloat = 1, alignment: Alignment = .center) {
        self.height = height
        self.alignment = alignment
    }

    var body: some View {
        Color(.separatorColor)
            .frame(height: 0.5)
            .frame(height: 1)  // Avoid subpixel rendering because a height of 0.5 does not work.
            .frame(height: height, alignment: alignment)
            .maxWidth()
    }
}
