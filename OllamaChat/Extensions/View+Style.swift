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


struct BorderDecoratedStyleModifier: ViewModifier {
    
    let paddingV: CGFloat
    let paddingH: CGFloat
    
    init(paddingV: CGFloat = 16, paddingH: CGFloat = 12) {
        self.paddingV = paddingV
        self.paddingH = paddingH
    }
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ocPrimaryBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.ocDividerColor, lineWidth: 1)
                    }
            }
    }
}
