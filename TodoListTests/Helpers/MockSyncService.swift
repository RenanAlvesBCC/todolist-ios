//
//  MockSyncService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

@testable import TodoList

final class MockSyncService: SyncServiceProtocol {
    var hasPendingOperations = false
    private(set) var processCallCount = 0
    private(set) var enqueuedOperations: [PendingOperation] = []

    func enqueue(_ operation: PendingOperation) {
        enqueuedOperations.append(operation)
        hasPendingOperations = true
    }

    func processPendingOperations() async {
        processCallCount += 1
        hasPendingOperations = false
    }
}
