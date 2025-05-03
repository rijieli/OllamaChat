//
//  ErrorModel.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 10.10.23.
//

import Foundation

struct ErrorModel: Identifiable {
    var id: String { errorTitle }
    
    var showError: Bool
    var errorTitle: String
    var errorMessage: String
}
