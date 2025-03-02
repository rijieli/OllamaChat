//
//  Response.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Foundation

struct ResponseModel: Decodable, Hashable {
    let model: String
    let createdAt: String
    let response: String?
    let done: Bool
    let message: ChatMessage
    let context: [Int]?
    let totalDuration: Int?
    let loadDuration: Int?
    let promptEvalCount: Int?
    let evalCount: Int?
    let evalDuration: Int?

    enum CodingKeys: String, CodingKey {
        case model
        case createdAt = "created_at"
        case response
        case done
        case message
        case context
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
    }

}

struct DownloadResponseModel: Decodable, Hashable {
    let status: String?
    let digest: String?
    let total: Double?
    let completed: Double?
}
