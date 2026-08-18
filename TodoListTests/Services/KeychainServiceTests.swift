//
//  KeychainServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
@testable import TodoList

final class MockKeychainService: KeychainServiceProtocol {
    var savedToken: String?
    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false

    func save(token: String) throws {
        if shouldThrowOnSave { throw KeychainError.saveFailed(-1) }
        savedToken = token
    }

    func loadToken() throws -> String {
        if shouldThrowOnLoad { throw KeychainError.notFound }
        guard let token = savedToken else { throw KeychainError.notFound }
        return token
    }

    func deleteToken() {
        savedToken = nil
    }
}

final class KeychainServiceTests: XCTestCase {

    private var service: KeychainService!

    override func setUp() {
        super.setUp()
        service = KeychainService()
        service.deleteToken()
    }

    override func tearDown() {
        service.deleteToken()
        service = nil
        super.tearDown()
    }

    func testSaveAndLoadToken() async throws {
        try service.save(token: "test-token-123")
        let loaded = try service.loadToken()
        XCTAssertEqual(loaded, "test-token-123")
    }

    func testLoadThrowsWhenNoTokenSaved() async {
        XCTAssertThrowsError(try service.loadToken())
    }

    func testDeleteRemovesToken() async throws {
        try service.save(token: "token-to-delete")
        service.deleteToken()
        XCTAssertThrowsError(try service.loadToken())
    }

    func testSaveOverwritesPreviousToken() async throws {
        try service.save(token: "primeiro")
        try service.save(token: "segundo")
        let loaded = try service.loadToken()
        XCTAssertEqual(loaded, "segundo")
    }
}
