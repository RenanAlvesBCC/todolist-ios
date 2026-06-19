//
//  AuthModelsTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class AuthModelsTests: XCTestCase {

    func testEncodesCredentialsToJSON() throws {
        let credentials = Credentials(username: "renan", password: "senha123")
        let data = try JSONEncoder().encode(credentials)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        XCTAssertEqual(json?["username"], "renan")
        XCTAssertEqual(json?["password"], "senha123")
    }

    func testDecodesLoginResponse() throws {
        let json = #"{"token":"eyJhbGciOiJIUzI1NiIs..."}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(LoginResponse.self, from: json)
        XCTAssertEqual(response.token, "eyJhbGciOiJIUzI1NiIs...")
    }

    func testDecodesAPIErrorResponse() throws {
        let json = #"{"error":"usuário ou senha incorretos"}"#.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIErrorResponse.self, from: json)
        XCTAssertEqual(response.error, "usuário ou senha incorretos")
    }
}
