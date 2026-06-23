//
//  SyncServiceProtocol.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

protocol SyncServiceProtocol {
    var hasPendingOperations: Bool { get }
    func enqueue(_ operation: PendingOperation)
    func processPendingOperations() async
}
