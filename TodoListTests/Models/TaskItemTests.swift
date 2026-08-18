//
//  TaskItemTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

@MainActor
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

    func testDecodesModernIDAndDateKeys() throws {
        let json = """
        {"id":3,"createdAt":"2026-06-18T10:05:00Z","updatedAt":"2026-06-18T10:05:00Z","text":"Filtro","completed":true,"position":4,"task_list_id":2}
        """.data(using: .utf8)!

        let item = try decoder.decode(TaskItem.self, from: json)
        XCTAssertEqual(item.id, 3)
        XCTAssertTrue(item.completed)
        XCTAssertEqual(item.position, 4)
    }

    func testEncodesTaskItem() throws {
        let item = TaskItem.stub(id: 10, text: "Óleo", completed: true, position: 2, taskListID: 1)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try JSONSerialization.jsonObject(with: encoder.encode(item)) as? [String: Any]
        XCTAssertEqual(json?["id"] as? Int, 10)
        XCTAssertEqual(json?["text"] as? String, "Óleo")
        XCTAssertEqual(json?["completed"] as? Bool, true)
        XCTAssertEqual(json?["task_list_id"] as? Int, 1)
    }

    func testDecodingFailsWhenRequiredFieldIsMissing() {
        let json = #"{ "ID": 1, "text": "Faltam os outros campos" }"#.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(TaskItem.self, from: json))
    }
}
