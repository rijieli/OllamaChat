//
//  UIApplication+.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

#if os(iOS)
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
