//
//  View+Style.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/3.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import SwiftUI

extension View {
    
    
    
}


struct TextBackgroundModifier: ViewModifier {
    
    let paddingV: CGFloat
    let paddingH: CGFloat
    
    init(paddingV: CGFloat = 16, paddingH: CGFloat = 12) {
        self.paddingV = paddingV
        self.paddingH = paddingH
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                    }
            }
    }
}
