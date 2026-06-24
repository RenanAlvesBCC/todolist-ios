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
    case authenticating
    case signedIn
}

@MainActor
@Observable
final class AuthViewModel {
    private(set) var state: AuthState = .signedOut
    var isLoading = false
    var errorMessage: String?

    private let apiClient: AuthAPIClient
    private let keychainService: KeychainServiceProtocol
    private let biometricService: BiometricServiceProtocol

    init(
        apiClient: AuthAPIClient = APIClient(),
        keychainService: KeychainServiceProtocol = KeychainService(),
        biometricService: BiometricServiceProtocol = BiometricService()
    ) {
        self.apiClient = apiClient
        self.keychainService = keychainService
        self.biometricService = biometricService
    }

    // MARK: - Biometric

    func attemptBiometricLogin() async {
        guard biometricService.isAvailable,
              let token = try? keychainService.loadToken() else {
            return
        }

        state = .authenticating

        do {
            let success = try await biometricService.authenticate(reason: L10n.Biometric.reason)
            if success {
                apiClient.restoreToken(token)
                state = .signedIn
            } else {
                state = .signedOut
            }
        } catch {
            // Usuário cancelou ou biometria falhou — volta pro login silenciosamente
            state = .signedOut
        }
    }

    // MARK: - Auth

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
            let response = try await apiClient.login(username: username, password: password)
            try? keychainService.save(token: response.token)
            state = .signedIn
        } catch {
            errorMessage = message(for: error)
        }

        isLoading = false
    }

    func registerAndLogin(username: String, password: String) async {
        await register(username: username, password: password)
        guard errorMessage == nil else { return }
        await login(username: username, password: password)
    }

    func logout() async {
        do {
            try await apiClient.logout()
        } catch {
            // Mesmo se o servidor falhar, limpa local e desloga
        }
        keychainService.deleteToken()
        state = .signedOut
    }

    // MARK: - Helpers

    private func validate(username: String, password: String) -> Bool {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            errorMessage = L10n.Auth.fillCredentials
            return false
        }
        return true
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.userMessage ?? error.localizedDescription
    }
}
