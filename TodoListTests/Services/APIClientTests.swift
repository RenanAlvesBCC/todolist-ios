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
    private(set) var requests: [URLRequest] = []
    private var responseQueue: [(data: Data, statusCode: Int)] = []

    func enqueue(data: Data, statusCode: Int = 200) {
        responseQueue.append((data, statusCode))
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        requests.append(request)

        let (responseData, code): (Data, Int)
        if !responseQueue.isEmpty {
            (responseData, code) = responseQueue.removeFirst()
        } else {
            (responseData, code) = (dataToReturn, statusCode)
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
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
    
    func testFetchTasksThrowsWhenNotAuthenticated() async {
        let mock = MockURLSession()
        let client = APIClient(session: mock)

        do {
            _ = try await client.fetchTasks(completed: nil, search: "", page: 1, limit: 10)
            XCTFail("Era esperado um erro de autenticação")
        } catch APIError.notAuthenticated {
            // esperado
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testFetchTasksSendsTokenAndQueryParameters() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"tasks":[],"page":1,"limit":10,"total":0,"total_pages":0}"#.data(using: .utf8)!)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        _ = try await client.fetchTasks(completed: false, search: "estudar", page: 2, limit: 5)

        let taskRequest = mock.requests.last
        XCTAssertEqual(taskRequest?.httpMethod, "GET")
        XCTAssertEqual(taskRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer fake-token")

        let query = taskRequest?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        XCTAssertTrue(query?.contains(URLQueryItem(name: "completed", value: "false")) ?? false)
        XCTAssertTrue(query?.contains(URLQueryItem(name: "search", value: "estudar")) ?? false)
    }

    func testCreateTaskSendsPostAndReturnsDecodedTask() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"ID":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Estudar Go","description":"","completed":false,"user_id":1}"#.data(using: .utf8)!, statusCode: 201)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        let task = try await client.createTask(title: "Estudar Go", description: "")

        XCTAssertEqual(task.title, "Estudar Go")
        XCTAssertEqual(mock.requests.last?.httpMethod, "POST")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/tasks")
    }

    func testDeleteTaskSucceedsOn204NoContent() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        try await client.deleteTask(id: 1)

        XCTAssertEqual(mock.requests.last?.httpMethod, "DELETE")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/tasks/1")
    }
}
