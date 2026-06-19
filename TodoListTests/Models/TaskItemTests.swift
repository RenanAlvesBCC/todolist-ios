//
//  TaskItemTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class TaskItemTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testDecodesTaskItemFromAPIJSON() throws {
        let json = """
        {
            "ID": 10,
            "CreatedAt": "2026-06-18T10:05:00Z",
            "UpdatedAt": "2026-06-18T10:05:00Z",
            "DeletedAt": null,
            "text": "Leite",
            "completed": false,
            "task_list_id": 1
        }
        """.data(using: .utf8)!

        let item = try decoder.decode(TaskItem.self, from: json)

        XCTAssertEqual(item.id, 10)
        XCTAssertEqual(item.text, "Leite")
        XCTAssertFalse(item.completed)
        XCTAssertEqual(item.taskListID, 1)
    }

    func testDecodingFailsWhenRequiredFieldIsMissing() {
        let json = #"{ "ID": 1, "text": "Faltam os outros campos" }"#.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(TaskItem.self, from: json))
    }
}
