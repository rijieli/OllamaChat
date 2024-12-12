//
//  TextSpeechCenter.swift
//  OllamaChat
//
//  Created by Roger on 2024/12/12.
//  Copyright © 2024 IdeasForm. All rights reserved.
//

import AVFoundation
import NaturalLanguage

public class TextSpeechCenter: NSObject, ObservableObject {

    enum Constant {
        static let genderPreferenceKey = "VoiceGenderPreference"
    }

    public static let shared = TextSpeechCenter()

    public var voiceGenderPreference: AVSpeechSynthesisVoiceGender = {
        let savedValue =
            UserDefaults
            .standard.value(
                forKey: Constant.genderPreferenceKey
            ) as? Int
        return savedValue.flatMap(AVSpeechSynthesisVoiceGender.init(rawValue:)) ?? .unspecified
    }()
    {
        didSet {
            UserDefaults.standard.set(
                voiceGenderPreference.rawValue,
                forKey: Constant.genderPreferenceKey
            )
        }
    }

    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isSpeaking = false
    
    private var preloaded = false
    private let preloadQueue = DispatchQueue(
        label: "com.ideasform.ollamachat.speechpreload",
        attributes: .concurrent
    )

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func start() {
        _ = synthesizer

        if !preloaded {
            let utterance = AVSpeechUtterance(string: "-")
            utterance.volume = 0
            preloadQueue.async { [weak self] in
                self?.synthesizer.speak(utterance)
            }
            preloaded = true
        }
    }

    private let languageAndVoice: [String: [AVSpeechSynthesisVoice]] = {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        var dict = [String: [AVSpeechSynthesisVoice]]()
        allVoices.forEach { voice in
            let langCode = voice.mappedNLLangCode
            if dict[langCode] == nil {
                dict[langCode] = []
            }
            dict[langCode]?.append(voice)
        }
        dict.forEach { (key, value) in
            dict[key] = value.sorted { $0.quality.rawValue > $1.quality.rawValue }
        }
        return dict
    }()

    public func read(_ str: String) {
        stopImmediate()
        isSpeaking = true
        
        guard let language = detectLanguage(of: str) else {
            let utterance = AVSpeechUtterance(string: str)
            synthesizer.speak(utterance)
            return
        }
        let utterance = AVSpeechUtterance(string: str)
        let matchedVoice = getVoice(language: language)
        utterance.voice = matchedVoice
        synthesizer.speak(utterance)
    }

    private func getVoice(language: String) -> AVSpeechSynthesisVoice? {
        guard let voices = languageAndVoice[language] else { return nil }
        let gender = voiceGenderPreference
        if let voice = voices.first(where: { $0.gender == gender }) {
            return voice
        } else {
            return voices.first
        }
    }

    private func detectLanguage(of text: String) -> String? {
        guard !text.isEmpty else { return nil }
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(text)
        guard let dominantLanguage = languageRecognizer.dominantLanguage else { return nil }
        return dominantLanguage.rawValue
    }

    func stopImmediate() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

extension TextSpeechCenter: AVSpeechSynthesizerDelegate {
    public func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        isSpeaking = false
    }
}

extension AVSpeechSynthesisVoice {

    fileprivate var mappedNLLangCode: String {
        let mappedToNLLangCode: String
        switch language {
        case "zh-CN":
            mappedToNLLangCode = "zh-Hans"
        case "zh-TW":
            mappedToNLLangCode = "zh-Hant"
        case "en-US":
            mappedToNLLangCode = "en"
        case "en-GB":
            mappedToNLLangCode = "en"
        case "es-ES":
            mappedToNLLangCode = "es"
        case "fr-FR":
            mappedToNLLangCode = "fr"
        case "de-DE":
            mappedToNLLangCode = "de"
        case "ja-JP":
            mappedToNLLangCode = "ja"
        case "ko-KR":
            mappedToNLLangCode = "ko"
        case "it-IT":
            mappedToNLLangCode = "it"
        default:
            mappedToNLLangCode = language
        }
        return mappedToNLLangCode
    }

}
