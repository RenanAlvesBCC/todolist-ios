//
//  APIClientTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MockURLSession: URLSessionProtocol {
    var dataToReturn = Data()
    var statusCode = 200
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (dataToReturn, response)
    }
}

final class APIClientTests: XCTestCase {

    func testLoginSuccessReturnsAndStoresToken() async throws {
        let mock = MockURLSession()
        mock.dataToReturn = #"{"token":"eyJhbGciOiJIUzI1NiIs..."}"#.data(using: .utf8)!
        mock.statusCode = 200

        let client = APIClient(session: mock)
        let response = try await client.login(username: "renan", password: "senha123")

        XCTAssertEqual(response.token, "eyJhbGciOiJIUzI1NiIs...")
        XCTAssertEqual(client.token, "eyJhbGciOiJIUzI1NiIs...")
        XCTAssertEqual(mock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mock.lastRequest?.url?.path, "/login")
    }

    func testLoginFailureThrowsServerErrorWithMessage() async {
        let mock = MockURLSession()
        mock.dataToReturn = #"{"error":"usuário ou senha incorretos"}"#.data(using: .utf8)!
        mock.statusCode = 401

        let client = APIClient(session: mock)

        do {
            _ = try await client.login(username: "renan", password: "errada")
            XCTFail("Era esperado um erro, mas o login não lançou nada")
        } catch APIError.server(let message) {
            XCTAssertEqual(message, "usuário ou senha incorretos")
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }
}
