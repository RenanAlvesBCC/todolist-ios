//
//  Auth.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

struct Credentials: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
}

struct MessageResponse: Codable {
    let message: String
}

struct APIErrorResponse: Codable {
    let error: String
}
