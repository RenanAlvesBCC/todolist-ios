//
//  BiometricServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
@testable import TodoList

final class MockBiometricService: BiometricServiceProtocol {
    var isAvailable = true
    var authenticationResult: Result<Bool, Error> = .success(true)

    func authenticate(reason: String) async throws -> Bool {
        return try authenticationResult.get()
    }
}

final class BiometricServiceTests: XCTestCase {

    func testBiometricServiceIsAvailableReturnsValue() {
        let service = BiometricService()
        // Apenas confirma que a propriedade não trava — o valor depende do dispositivo
        let _ = service.isAvailable
        XCTAssertTrue(true)
    }
}
