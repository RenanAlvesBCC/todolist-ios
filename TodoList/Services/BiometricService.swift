//
//  BiometricService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import LocalAuthentication

final class BiometricService: BiometricServiceProtocol {
    var isAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = L10n.Biometric.fallback
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        )
    }
}
