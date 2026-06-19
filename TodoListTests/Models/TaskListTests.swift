//
//  TaskListTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class TaskListTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testDecodesTaskListWithNestedItemsFromAPIJSON() throws {
        let json = """
        {
            "ID": 1,
            "CreatedAt": "2026-06-18T10:00:00Z",
            "UpdatedAt": "2026-06-18T10:00:00Z",
            "DeletedAt": null,
            "title": "Compras da semana",
            "user_id": 1,
            "items": [
                {"ID":10,"CreatedAt":"2026-06-18T10:05:00Z","UpdatedAt":"2026-06-18T10:05:00Z","text":"Leite","completed":false,"task_list_id":1},
                {"ID":11,"CreatedAt":"2026-06-18T10:06:00Z","UpdatedAt":"2026-06-18T10:06:00Z","text":"Pão","completed":true,"task_list_id":1}
            ]
        }
        """.data(using: .utf8)!

        let list = try decoder.decode(TaskList.self, from: json)

        XCTAssertEqual(list.title, "Compras da semana")
        XCTAssertEqual(list.items.count, 2)
        XCTAssertEqual(list.items.first?.text, "Leite")
        XCTAssertTrue(list.items.last?.completed ?? false)
    }

    func testDecodesTaskListWithEmptyItemsArray() throws {
        let json = """
        {"ID":2,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Nova lista","user_id":1,"items":[]}
        """.data(using: .utf8)!

        let list = try decoder.decode(TaskList.self, from: json)
        XCTAssertTrue(list.items.isEmpty)
    }
}
