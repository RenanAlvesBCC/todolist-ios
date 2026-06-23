//
//  KeychainServiceProtocol.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

protocol KeychainServiceProtocol {
    func save(token: String) throws
    func loadToken() throws -> String
    func deleteToken()
}
