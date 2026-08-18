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

    func testDecodedReturnsNilForInvalidJSON() {
        let operation = PendingOperation(type: .deleteList, payload: DeleteListPayload(id: 1))
        operation.payloadJSON = "{not-json"
        XCTAssertNil(operation.decoded(as: DeleteListPayload.self))
    }

    func testProcessPendingOperationsReturnsEarlyWhenQueueIsEmpty() async {
        await syncService.processPendingOperations()
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testProcessCreateListReplacesTempID() async {
        mockAPI.createListResult = .success(.stub(id: 42, title: "Civic"))
        syncService.enqueue(PendingOperation(
            type: .createList,
            payload: CreateListPayload(title: "Civic", tempID: -1)
        ))

        await syncService.processPendingOperations()

        XCTAssertFalse(syncService.hasPendingOperations)
        XCTAssertEqual(mockCache.replacedTempIDs.first?.temp, -1)
        XCTAssertEqual(mockCache.replacedTempIDs.first?.real.id, 42)
    }

    func testProcessUpdateListUpsertsResult() async {
        syncService.enqueue(PendingOperation(
            type: .updateList,
            payload: UpdateListPayload(id: 1, title: "Gol")
        ))

        await syncService.processPendingOperations()

        XCTAssertEqual(mockAPI.lastUpdateList?.title, "Gol")
        XCTAssertEqual(mockCache.savedLists.first?.title, "Gol")
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testProcessCreateItemReplacesTempItemID() async {
        mockAPI.addItemResult = .success(.stub(id: 9, text: "Óleo"))
        syncService.enqueue(PendingOperation(
            type: .createItem,
            payload: CreateItemPayload(listID: 1, text: "Óleo", tempID: -2)
        ))

        await syncService.processPendingOperations()

        XCTAssertEqual(mockCache.replacedTempItemIDs.first?.temp, -2)
        XCTAssertEqual(mockCache.replacedTempItemIDs.first?.real.id, 9)
    }

    func testProcessUpdateItemUpsertsResult() async {
        mockAPI.updateItemResult = .success(.stub(id: 5, text: "Filtro", completed: true))
        syncService.enqueue(PendingOperation(
            type: .updateItem,
            payload: UpdateItemPayload(listID: 1, itemID: 5, text: "Filtro", completed: true)
        ))

        await syncService.processPendingOperations()

        XCTAssertEqual(mockCache.upsertedItems.last?.text, "Filtro")
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testProcessDeleteItemCallsAPI() async {
        syncService.enqueue(PendingOperation(
            type: .deleteItem,
            payload: DeleteItemPayload(listID: 1, itemID: 5)
        ))

        await syncService.processPendingOperations()

        XCTAssertEqual(mockAPI.lastDeleteItemInput?.itemID, 5)
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testProcessReorderListsAndItems() async {
        syncService.enqueue(PendingOperation(type: .reorderLists, payload: ReorderListsPayload(ids: [2, 1])))
        await syncService.processPendingOperations()
        XCTAssertEqual(mockAPI.reorderListsIDs, [2, 1])

        syncService.enqueue(PendingOperation(
            type: .reorderItems,
            payload: ReorderItemsPayload(listID: 3, ids: [8, 7])
        ))
        await syncService.processPendingOperations()
        XCTAssertEqual(mockAPI.reorderItemsInput?.ids, [8, 7])
    }

    func testProcessChangeStatusAndQuoteAndFlag() async {
        syncService.enqueue(PendingOperation(
            type: .changeStatus,
            payload: ChangeStatusPayload(listID: 1, status: "aguardando_peca")
        ))
        syncService.enqueue(PendingOperation(
            type: .createQuote,
            payload: CreateQuotePayload(listID: 1, text: "Pastilha")
        ))
        syncService.enqueue(PendingOperation(
            type: .createFlag,
            payload: CreateFlagPayload(listID: 1, flagType: "procurando_peca", note: "disco")
        ))

        await syncService.processPendingOperations()

        XCTAssertEqual(mockAPI.lastChangeStatus?.status, .aguardandoPeca)
        XCTAssertEqual(mockAPI.lastAddQuote?.text, "Pastilha")
        XCTAssertEqual(mockAPI.lastAddFlag?.flagType, "procurando_peca")
        XCTAssertFalse(syncService.hasPendingOperations)
    }

    func testInvalidPayloadIsDroppedAsSuccess() async {
        syncService.enqueue(PendingOperation(
            type: .createList,
            payload: DeleteListPayload(id: 1)
        ))

        await syncService.processPendingOperations()

        XCTAssertFalse(syncService.hasPendingOperations)
        XCTAssertEqual(mockAPI.createListCallCount, 0)
    }

    func testUnknownOperationTypeIsDropped() async {
        let operation = PendingOperation(type: .deleteList, payload: DeleteListPayload(id: 1))
        operation.operationType = "unknown"
        syncService.enqueue(operation)

        await syncService.processPendingOperations()

        XCTAssertFalse(syncService.hasPendingOperations)
        XCTAssertNil(mockAPI.lastDeletedListID)
    }

    func testInvalidChangeStatusIsDropped() async {
        syncService.enqueue(PendingOperation(
            type: .changeStatus,
            payload: ChangeStatusPayload(listID: 1, status: "invalido")
        ))

        await syncService.processPendingOperations()

        XCTAssertFalse(syncService.hasPendingOperations)
        XCTAssertNil(mockAPI.lastChangeStatus)
    }

    func testFailedOperationIncrementsRetryCountWithoutDeleting() async {
        mockAPI.deleteListError = APIError.server(message: "falhou")
        syncService.enqueue(PendingOperation(type: .deleteList, payload: DeleteListPayload(id: 1)))

        await syncService.processPendingOperations()

        XCTAssertTrue(syncService.hasPendingOperations)
        let remaining = fetchOperations()
        XCTAssertEqual(remaining.first?.retryCount, 1)
    }

    func testSkipsOperationsAfterFiveFailuresWithoutDeleting() async {
        mockAPI.deleteListError = APIError.server(message: "falhou")
        let operation = PendingOperation(type: .deleteList, payload: DeleteListPayload(id: 1))
        operation.retryCount = 5
        syncService.enqueue(operation)

        await syncService.processPendingOperations()

        XCTAssertTrue(syncService.hasPendingOperations)
        XCTAssertNil(mockAPI.lastDeletedListID)
        XCTAssertEqual(fetchOperations().first?.retryCount, 5)
    }

    private func fetchOperations() -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>()
        return (try? modelContainer.mainContext.fetch(descriptor)) ?? []
    }
}
