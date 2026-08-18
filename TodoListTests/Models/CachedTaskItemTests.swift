//
//  CachedTaskItemTests.swift
//  TodoListTests
//

import XCTest
import SwiftData
@testable import TodoList

@MainActor
final class CachedTaskItemTests: XCTestCase {

    func testInitStoresFieldsAndToTaskItemMapsThem() {
        let cached = CachedTaskItem(
            serverID: 10,
            text: "Troca de óleo",
            completed: true,
            position: 2,
            taskListServerID: 7
        )

        XCTAssertEqual(cached.serverID, 10)
        XCTAssertEqual(cached.text, "Troca de óleo")
        XCTAssertTrue(cached.completed)
        XCTAssertEqual(cached.position, 2)
        XCTAssertEqual(cached.taskListServerID, 7)

        let item = cached.toTaskItem()
        XCTAssertEqual(item.id, 10)
        XCTAssertEqual(item.text, "Troca de óleo")
        XCTAssertTrue(item.completed)
        XCTAssertEqual(item.position, 2)
        XCTAssertEqual(item.taskListID, 7)
        XCTAssertEqual(item.createdAt, cached.syncedAt)
        XCTAssertEqual(item.updatedAt, cached.syncedAt)
    }

    func testCachedTaskListToTaskListUsesItemsAndStatus() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: CachedTaskList.self, CachedTaskItem.self, PendingOperation.self,
            configurations: config
        )
        let list = CachedTaskList(
            serverID: 3,
            title: "Civic",
            userID: 1,
            position: 1,
            status: VehicleStatus.aguardandoPeca.rawValue
        )
        let item = CachedTaskItem(
            serverID: 20, text: "Pastilha", completed: false, position: 0, taskListServerID: 3
        )
        list.items.append(item)
        container.mainContext.insert(list)
        container.mainContext.insert(item)

        let converted = list.toTaskList()
        XCTAssertEqual(converted.id, 3)
        XCTAssertEqual(converted.title, "Civic")
        XCTAssertEqual(converted.status, .aguardandoPeca)
        XCTAssertEqual(converted.items.count, 1)
        XCTAssertEqual(converted.items.first?.text, "Pastilha")
    }

    func testCachedTaskListFallsBackToEmAndamentoOnUnknownStatus() {
        let list = CachedTaskList(serverID: 1, title: "Gol", userID: 1, position: 0, status: "desconhecido")
        XCTAssertEqual(list.toTaskList().status, .emAndamento)
    }
}
