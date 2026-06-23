//
//  APIError+Message.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

extension APIError {
    var userMessage: String {
        switch self {
        case .server(let message): return message
        case .invalidResponse: return L10n.Error.serverUnavailable
        case .decoding: return L10n.Error.unexpectedResponse
        case .notAuthenticated: return L10n.Error.sessionExpired
        }
    }
}
