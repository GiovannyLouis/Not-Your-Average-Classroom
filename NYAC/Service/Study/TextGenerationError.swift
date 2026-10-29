//
//  TextGenerationError.swift
//  NYAC
//
//  Created by Vrz on 29/10/26.
//

import Foundation

enum TextGenerationError: LocalizedError {
    case unavailable(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .unavailable(let reason):
            return reason
        case .emptyResponse:
            return "The model returned an empty response."
        }
    }
}
