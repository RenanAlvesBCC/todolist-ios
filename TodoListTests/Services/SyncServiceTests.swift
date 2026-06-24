//
//  SyncServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
import SwiftData
@testable import TodoList


@MainActor
final class SyncServiceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var syncService: SyncService!
    private var mockAPI: MockTaskAPIClient!
    private var mockCache: MockCacheService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: CachedTaskList.self, CachedTaskItem.self, PendingOperation.self,
            configurations: config
        )
        mockAPI = MockTaskAPIClient()
        mockCache = MockCacheService()
        syncService = SyncService(
            apiClient: mockAPI,
            cacheService: mockCache,
            modelContext: modelContainer.mainContext
        )
    }

    func testHasPendingOperationsReturnsFalseWhenQueueIsEmpty() {
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testHasPendingOperationsReturnsTrueAfterEnqueue() {
        syncService.enqueue(PendingOperation(
            type: .deleteList,
            payload: DeleteListPayload(id: 1)
        ))
        XCTAssertTrue(syncService.hasPendingOperations)
    }

    func testProcessPendingOperationsClearsQueueOnSuccess() async {
        syncService.enqueue(PendingOperation(
            type: .deleteList,
            payload: DeleteListPayload(id: 1)
        ))

        await syncService.processPendingOperations()

        XCTAssertFalse(syncService.hasPendingOperations)
        XCTAssertEqual(mockAPI.lastDeletedListID, 1)
    }
}
