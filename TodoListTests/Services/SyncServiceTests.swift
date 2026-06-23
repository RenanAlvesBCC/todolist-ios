//
//  SyncServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
import SwiftData
@testable import TodoList

final class MockCacheService: CacheServiceProtocol {
    var savedLists: [TaskList] = []
    var deletedListIDs: [Int] = []
    var upsertedItems: [TaskItem] = []
    var deletedItemIDs: [Int] = []
    private(set) var replacedTempIDs: [(temp: Int, real: TaskList)] = []

    func saveLists(_ lists: [TaskList]) { savedLists = lists }
    func loadLists(userID: Int) -> [TaskList] { savedLists }
    func upsertList(_ list: TaskList) { savedLists.append(list) }
    func deleteList(serverID: Int) { deletedListIDs.append(serverID) }
    func upsertItem(_ item: TaskItem) { upsertedItems.append(item) }
    func deleteItem(serverID: Int) { deletedItemIDs.append(serverID) }
    func replaceTempID(_ tempID: Int, with realList: TaskList) { replacedTempIDs.append((tempID, realList)) }
    func replaceTempItemID(_ tempID: Int, with realItem: TaskItem) {}
}

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
