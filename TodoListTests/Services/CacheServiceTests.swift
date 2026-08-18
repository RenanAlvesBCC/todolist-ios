//
//  CacheServiceTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
import SwiftData
@testable import TodoList

@MainActor
final class CacheServiceTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var cacheService: CacheService!

    override class var defaultTestSuite: XCTestSuite {
            // Força execução serial pra evitar conflitos do ModelContext
            return super.defaultTestSuite
        }
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: CachedTaskList.self, CachedTaskItem.self, PendingOperation.self,
            configurations: config
        )
        cacheService = CacheService(modelContext: modelContainer.mainContext)
    }

    func testSaveAndLoadLists() {
        let lists = [TaskList.stub(id: 1, title: "Compras"), TaskList.stub(id: 2, title: "Trabalho")]
        cacheService.saveLists(lists)

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertEqual(loaded.count, 2)
    }

    func testLoadListsReturnsEmptyWhenNothingCached() {
        let loaded = cacheService.loadLists(userID: 99)
        XCTAssertTrue(loaded.isEmpty)
    }

    func testUpsertUpdatesExistingList() {
        let original = TaskList.stub(id: 1, title: "Antigo")
        cacheService.upsertList(original)

        var updated = original
        updated.title = "Novo"
        cacheService.upsertList(updated)

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertEqual(loaded.first?.title, "Novo")
    }

    func testDeleteListRemovesFromCache() {
        cacheService.upsertList(TaskList.stub(id: 1))
        cacheService.deleteList(serverID: 1)

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertTrue(loaded.isEmpty)
    }

    func testReplaceTempIDSubstitutesNegativeID() {
        let tempList = TaskList.stub(id: -1, title: "Temp")
        cacheService.upsertList(tempList)

        let realList = TaskList.stub(id: 42, title: "Temp")
        cacheService.replaceTempID(-1, with: realList)

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertEqual(loaded.first?.id, 42)
    }

    func testSaveListsRemovesStaleEntries() {
        cacheService.upsertList(TaskList.stub(id: 1, title: "A"))
        cacheService.upsertList(TaskList.stub(id: 2, title: "B"))

        // Servidor retorna só a lista 1 agora
        cacheService.saveLists([TaskList.stub(id: 1, title: "A")])

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, 1)
    }

    func testUpsertListUpdatesExistingItemsAndInsertsNewOnes() {
        cacheService.upsertList(TaskList.stub(id: 1, items: [TaskItem.stub(id: 10, text: "Antigo")]))

        cacheService.upsertList(TaskList.stub(
            id: 1,
            title: "Civic",
            items: [
                TaskItem.stub(id: 10, text: "Novo", completed: true, position: 1),
                TaskItem.stub(id: 11, text: "Filtro")
            ]
        ))

        let loaded = cacheService.loadLists(userID: 1)
        XCTAssertEqual(loaded.first?.title, "Civic")
        XCTAssertEqual(loaded.first?.items.count, 2)
        XCTAssertEqual(loaded.first?.items.first { $0.id == 10 }?.text, "Novo")
        XCTAssertEqual(loaded.first?.items.first { $0.id == 10 }?.completed, true)
    }

    func testUpsertItemUpdatesExistingAndInsertsWhenListExists() {
        cacheService.upsertList(TaskList.stub(id: 1, items: [TaskItem.stub(id: 10, text: "A")]))
        cacheService.upsertItem(TaskItem.stub(id: 10, text: "Atualizado", completed: true))
        cacheService.upsertItem(TaskItem.stub(id: 11, text: "Novo", taskListID: 1))

        let items = cacheService.loadLists(userID: 1).first?.items ?? []
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first { $0.id == 10 }?.text, "Atualizado")
        XCTAssertTrue(items.contains { $0.id == 11 })
    }

    func testUpsertItemDoesNothingWhenListIsMissing() {
        cacheService.upsertItem(TaskItem.stub(id: 1, taskListID: 99))
        XCTAssertTrue(cacheService.loadLists(userID: 1).isEmpty)
    }

    func testDeleteItemRemovesFromCache() {
        cacheService.upsertList(TaskList.stub(id: 1, items: [TaskItem.stub(id: 10)]))
        cacheService.deleteItem(serverID: 10)

        XCTAssertTrue(cacheService.loadLists(userID: 1).first?.items.isEmpty ?? false)
    }

    func testDeleteItemNoOpWhenMissing() {
        cacheService.deleteItem(serverID: 999)
        XCTAssertTrue(cacheService.loadLists(userID: 1).isEmpty)
    }

    func testReplaceTempItemIDSubstitutesNegativeID() {
        cacheService.upsertList(TaskList.stub(id: 1, items: [TaskItem.stub(id: -1, text: "Temp")]))
        cacheService.replaceTempItemID(-1, with: TaskItem.stub(id: 42, text: "Temp"))

        XCTAssertEqual(cacheService.loadLists(userID: 1).first?.items.first?.id, 42)
    }

    func testDeleteListNoOpWhenMissing() {
        cacheService.deleteList(serverID: 999)
        XCTAssertTrue(cacheService.loadLists(userID: 1).isEmpty)
    }

    func testLoadListsReturnsSortedByPosition() {
        cacheService.upsertList(TaskList.stub(id: 2, title: "B", position: 1))
        cacheService.upsertList(TaskList.stub(id: 1, title: "A", position: 0))

        XCTAssertEqual(cacheService.loadLists(userID: 1).map(\.id), [1, 2])
    }

    func testSaveListsPersistsStatus() {
        var list = TaskList.stub(id: 1, title: "Civic")
        list.status = .aguardandoPeca
        cacheService.saveLists([list])

        XCTAssertEqual(cacheService.loadLists(userID: 1).first?.status, .aguardandoPeca)
    }
}
