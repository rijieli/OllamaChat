//
//  ChatViewModel+.swift
//  OllamaChat
//
//  Created by Roger on 2025/2/18.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

extension ChatViewModel {
    var chatOptions: ChatOptions {
        ChatOptions(
            temperature: temperature,
            topP: topP,
            topK: topK,
            minP: minP,
            numPredict: numPredict,
            repeatLastN: repeatLastN,
            repeatPenalty: repeatPenalty,
            seed: seed,
            numCtx: numCtx,
            mirostat: mirostat,
            mirostatEta: mirostatEta,
            mirostatTau: mirostatTau
        )
    }
    
    func resetChatOptionsToDefault() {
        mirostat = 0
        mirostatEta = 0.1
        mirostatTau = 5.0
        numCtx = 2048
        repeatLastN = 64
        repeatPenalty = 1.1
        temperature = 0.6
        seed = 0
        numPredict = -1
        topK = 40
        topP = 0.9
        minP = 0.0
    }
}
