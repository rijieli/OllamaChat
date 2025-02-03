//
//  Locale+.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/12.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import Foundation

extension Locale {
    static var isZhHans: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh-Hans") == true
    }

    static var isZhHant: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh-Hant") == true
    }

    static var isEn: Bool {
        Locale.preferredLanguages.first?.hasPrefix("en") == true
    }
    
    static var enUS: Locale {
        Locale(identifier: "en_US")
    }
}
