//
//  AuthViewModel.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation
import Observation

enum AuthState: Equatable {
    case signedOut
    case signedIn
}

@MainActor
@Observable
final class AuthViewModel {
    private(set) var state: AuthState = .signedOut
    var isLoading = false
    var errorMessage: String?

    private let apiClient: AuthAPIClient

    init(apiClient: AuthAPIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func registerAndLogin(username: String, password: String) async {
        await register(username: username, password: password)
        guard errorMessage == nil else { return }
        await login(username: username, password: password)
    }
    
    func register(username: String, password: String) async {
        guard validate(username: username, password: password) else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiClient.register(username: username, password: password)
        } catch {
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func login(username: String, password: String) async {
        guard validate(username: username, password: password) else { return }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await apiClient.login(username: username, password: password)
            state = .signedIn
        } catch {
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func logout() {
        state = .signedOut
    }

    private func validate(username: String, password: String) -> Bool {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            errorMessage = "Preencha usuário e senha"
            return false
        }
        return true
    }

    private func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return error.localizedDescription
        }
        switch apiError {
        case .server(let message): return message
        case .invalidResponse: return "Não foi possível conectar ao servidor"
        case .decoding: return "Resposta inesperada do servidor"
        }
    }
}
