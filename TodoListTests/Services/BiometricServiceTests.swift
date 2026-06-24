//
//  BiometricServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
@testable import TodoList

final class BiometricServiceTests: XCTestCase {

    func testMockBiometricServiceIsAvailableByDefault() {
        let mock = MockBiometricService()
        XCTAssertTrue(mock.isAvailable)
    }

    func testMockBiometricServiceAuthenticatesSuccessfully() async throws {
        let mock = MockBiometricService()
        let result = try await mock.authenticate(reason: "test")
        XCTAssertTrue(result)
    }

    func testMockBiometricServiceCanSimulateFailure() async {
        let mock = MockBiometricService()
        mock.authenticationResult = .success(false)
        let result = try? await mock.authenticate(reason: "test")
        XCTAssertEqual(result, false)
    }
}
