//
//  APIErrorMessageTests.swift
//  TodoListTests
//

import XCTest
@testable import TodoList

@MainActor
final class APIErrorMessageTests: XCTestCase {

    func testUserMessageForEachCase() {
        XCTAssertEqual(APIError.server(message: "falhou").userMessage, "falhou")
        XCTAssertEqual(APIError.invalidResponse.userMessage, L10n.Error.serverUnavailable)
        XCTAssertEqual(APIError.decoding.userMessage, L10n.Error.unexpectedResponse)
        XCTAssertEqual(APIError.notAuthenticated.userMessage, L10n.Error.sessionExpired)
    }
}
