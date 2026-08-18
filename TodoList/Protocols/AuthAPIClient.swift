//
//  AuthAPIClient.swift
//  TodoList
//

import Foundation

protocol AuthAPIClient {
    func register(username: String, password: String) async throws -> MessageResponse
    func login(username: String, password: String) async throws -> LoginResponse
    func logout() async throws
    func restoreToken(_ token: String)
    func fetchWorkspace() async throws -> Workspace
    func acceptInvite(code: String) async throws
}
