//
//  ErrorMessages.swift
//  Ollama Swift
//
//  Created by Karim ElGhandour on 14.10.23.
//

import Foundation

private func formattedErrorSuffix(_ error: Error?) -> String {
    guard let description = error?.localizedDescription
        .trimmingCharacters(in: .whitespacesAndNewlines),
        !description.isEmpty
    else {
        return ""
    }

    return " \(description)"
}

func invalidURLError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "Invalid URL given",
        errorMessage:
            "Make sure that Ollama is installed and online. Check Help for further info.\(formattedErrorSuffix(error))"
    )
}

func invalidDataError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "Invalid Data received",
        errorMessage:
            "Looks like there is a problem retrieving the data.\(formattedErrorSuffix(error))"
    )
}

func invalidTagsDataError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "No models have been detected!",
        errorMessage:
            "To download your first model, click on 'Manage Models', and enter a model name in the 'Add Model' field and click download.\(formattedErrorSuffix(error))"
    )
}

func invalidResponseError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "Invalid Response",
        errorMessage:
            "Looks like you are receiving a response other than 200!\(formattedErrorSuffix(error))"
    )
}

func unreachableError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "Server is unreachable - Timeout",
        errorMessage:
            "Make sure Ollama ( https://ollama.com/ ) is installed and running. If a different IP/PORT is used other than the default, change it in the app settings. Adjust the timeout value in the settings.\(formattedErrorSuffix(error))"
    )
}

func genericError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "An error has occurred",
        errorMessage:
            "If restarting ollama does not fix it, please report the bug.\(formattedErrorSuffix(error))"
    )
}

func noModelsError(error: Error?) -> ErrorModel {
    return ErrorModel(
        showError: true,
        errorTitle: "No models found",
        errorMessage: "Click the gear icon and download a model"
    )
}
