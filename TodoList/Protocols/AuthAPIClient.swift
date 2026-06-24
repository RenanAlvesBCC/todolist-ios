//
//  AuthAPIClient.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

protocol AuthAPIClient {
    func register(username: String, password: String) async throws -> MessageResponse
    func login(username: String, password: String) async throws -> LoginResponse
    func logout() async throws
    func restoreToken(_ token: String)
}
