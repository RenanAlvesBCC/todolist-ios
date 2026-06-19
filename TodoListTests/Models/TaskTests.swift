//
//  TaskTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class TaskTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func testDecodesTaskFromAPIJSON() throws {
        let json = """
        {
            "ID": 1,
            "CreatedAt": "2026-06-18T10:00:00Z",
            "UpdatedAt": "2026-06-18T10:00:00Z",
            "DeletedAt": null,
            "title": "Estudar Go",
            "description": "Terminar a fase 5 do projeto",
            "completed": false,
            "user_id": 1
        }
        """.data(using: .utf8)!

        let task = try decoder.decode(Task.self, from: json)

        XCTAssertEqual(task.id, 1)
        XCTAssertEqual(task.title, "Estudar Go")
        XCTAssertEqual(task.description, "Terminar a fase 5 do projeto")
        XCTAssertFalse(task.completed)
        XCTAssertEqual(task.userID, 1)
    }

    func testDecodingFailsWhenRequiredFieldIsMissing() {
        let json = """
        { "ID": 1, "title": "Faltam os outros campos obrigatórios" }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(Task.self, from: json))
    }
}
