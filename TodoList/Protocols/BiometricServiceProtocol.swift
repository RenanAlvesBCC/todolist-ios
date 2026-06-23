//
//  BiometricServiceProtocol.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

protocol BiometricServiceProtocol {
    var isAvailable: Bool { get }
    func authenticate(reason: String) async throws -> Bool
}
