//
//  APIClient.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

enum APIError: Error, Equatable {
    case invalidResponse
    case server(message: String)
    case decoding
    case notAuthenticated
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSessionProtocol
    private(set) var token: String?

    init(baseURL: URL = URL(string: "http://localhost:8080")!,
         session: URLSessionProtocol = URLSession.shared) {
        self.baseURL = baseURL
        self.session = session
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    // MARK: - Autenticação

    func register(username: String, password: String) async throws -> MessageResponse {
        try await send(method: "POST", path: "/register", body: Credentials(username: username, password: password))
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        let response: LoginResponse = try await send(method: "POST", path: "/login", body: Credentials(username: username, password: password))
        self.token = response.token
        return response
    }

    func logout() {
        token = nil
    }

    // MARK: - Listas e itens

    func fetchLists(search: String, page: Int, limit: Int) async throws -> TaskListResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/lists"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        components.queryItems = queryItems

        let request = try makeRequest(url: components.url!, method: "GET", authenticated: true)
        return try await perform(request)
    }

    func createList(title: String) async throws -> TaskList {
        try await send(method: "POST", path: "/api/lists", body: CreateListInput(title: title), authenticated: true)
    }

    func updateList(id: Int, title: String) async throws -> TaskList {
        try await send(method: "PUT", path: "/api/lists/\(id)", body: UpdateListInput(title: title), authenticated: true)
    }

    func deleteList(id: Int) async throws {
        let request = try makeRequest(url: baseURL.appendingPathComponent("/api/lists/\(id)"), method: "DELETE", authenticated: true)
        try await performNoContent(request)
    }

    func addItem(listID: Int, text: String) async throws -> TaskItem {
        try await send(method: "POST", path: "/api/lists/\(listID)/items", body: CreateItemInput(text: text), authenticated: true)
    }

    func updateItem(listID: Int, itemID: Int, text: String, completed: Bool) async throws -> TaskItem {
        try await send(method: "PUT", path: "/api/lists/\(listID)/items/\(itemID)", body: UpdateItemInput(text: text, completed: completed), authenticated: true)
    }

    func deleteItem(listID: Int, itemID: Int) async throws {
        let request = try makeRequest(url: baseURL.appendingPathComponent("/api/lists/\(listID)/items/\(itemID)"), method: "DELETE", authenticated: true)
        try await performNoContent(request)
    }

    // MARK: - Núcleo privado

    private func makeRequest(url: URL, method: String, authenticated: Bool) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if authenticated {
            guard let token else { throw APIError.notAuthenticated }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func validate(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.server(message: apiError.error)
            }
            throw APIError.invalidResponse
        }
        return data
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        let validData = try validate(data: data, response: response)
        do {
            return try decoder.decode(Response.self, from: validData)
        } catch {
            throw APIError.decoding
        }
    }

    private func performNoContent(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)
        _ = try validate(data: data, response: response)
    }

    private func send<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        body: Body,
        authenticated: Bool = false
    ) async throws -> Response {
        var request = try makeRequest(url: baseURL.appendingPathComponent(path), method: method, authenticated: authenticated)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }
}

extension URLSession: URLSessionProtocol {}
extension APIClient: AuthAPIClient {}
extension APIClient: TaskAPIClient {}
