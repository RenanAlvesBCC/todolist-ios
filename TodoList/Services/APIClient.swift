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

    func register(username: String, password: String) async throws -> MessageResponse {
        try await post(path: "/register", body: Credentials(username: username, password: password))
    }

    func login(username: String, password: String) async throws -> LoginResponse {
        let response: LoginResponse = try await post(path: "/login", body: Credentials(username: username, password: password))
        self.token = response.token
        return response
    }

    private func post<Body: Encodable, Response: Decodable>(path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.server(message: apiError.error)
            }
            throw APIError.invalidResponse
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
