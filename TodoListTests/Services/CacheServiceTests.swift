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
}
