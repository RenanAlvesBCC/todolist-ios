//
//  MockBiometricServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

@testable import TodoList

final class MockBiometricService: BiometricServiceProtocol {
    var isAvailable = true
    var authenticationResult: Result<Bool, Error> = .success(true)

    func authenticate(reason: String) async throws -> Bool {
        return try authenticationResult.get()
    }
}
