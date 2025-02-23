//
//  ChatController.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 08.10.23.
//

import Foundation

var APIEndPoint: String {
    ChatViewModel.shared.apiEndPoint
}

func getLocalModels(timeout: Double? = nil) async throws -> ModelGroup {
    let endpoint = APIEndPoint + "tags"

    guard let url = URL(string: endpoint) else {
        throw NetError.invalidURL(error: nil)
    }

    let data: Data
    let response: URLResponse

    let timeoutRequest = ChatViewModel.shared.timeoutRequest
    let timeoutResource = ChatViewModel.shared.timeoutResource

    do {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = timeout ?? Double(timeoutRequest) ?? 60
        sessionConfig.timeoutIntervalForResource = Double(timeoutResource) ?? 604800
        (data, response) = try await URLSession(configuration: sessionConfig).data(from: url)
    } catch {
        throw NetError.unreachable(error: error)
    }

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw NetError.invalidResponse(error: nil)
    }
    do {
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ModelGroup.self, from: data)
        await MainActor.run {
            ChatViewModel.shared.tags = decoded
            ChatViewModel.shared.model = decoded.models.first?.name ?? ""
            if decoded.models.count == 0 {
                ChatViewModel.shared.errorModel = noModelsError(error: nil)
            } else {
                ChatViewModel.shared.errorModel.showError = false
            }
        }
        return decoded
    } catch {
        throw NetError.invalidData(error: error)
    }
}
