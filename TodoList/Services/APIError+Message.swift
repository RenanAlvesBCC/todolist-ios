//
//  APIError+Message.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

extension APIError {
    var userMessage: String {
        switch self {
        case .server(let message): return message
        case .invalidResponse: return "Não foi possível conectar ao servidor"
        case .decoding: return "Resposta inesperada do servidor"
        case .notAuthenticated: return "Sessão expirada, faça login novamente"
        }
    }
}
