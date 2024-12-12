//
//  AVSpeechSynthesisVoiceGender+.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/12.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import AVFoundation

extension AVSpeechSynthesisVoiceGender {
    
    var title: String {
        switch self {
        case .unspecified: "Unspecified"
        case .female: "Female"
        case .male: "Male"
        @unknown default:
            fatalError()
        }
    }
    
}
