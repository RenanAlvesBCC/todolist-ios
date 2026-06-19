//
//  TaskModelsTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class TaskModelsTests: XCTestCase {

    func testDecodesTaskListResponse() throws {
        let json = """
        {
            "tasks": [
                {"ID":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Estudar Go","description":"","completed":false,"user_id":1}
            ],
            "page": 1,
            "limit": 10,
            "total": 1,
            "total_pages": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(TaskListResponse.self, from: json)

        XCTAssertEqual(response.tasks.count, 1)
        XCTAssertEqual(response.tasks.first?.title, "Estudar Go")
        XCTAssertEqual(response.totalPages, 1)
    }

    func testEncodesCreateTaskInput() throws {
        let input = CreateTaskInput(title: "Nova lista", description: "Detalhes")
        let data = try JSONEncoder().encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        XCTAssertEqual(json?["title"], "Nova lista")
        XCTAssertEqual(json?["description"], "Detalhes")
    }

    func testEncodesUpdateTaskInputIncludingCompletedFlag() throws {
        let input = UpdateTaskInput(title: "Nova lista", description: "Detalhes", completed: true)
        let data = try JSONEncoder().encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["completed"] as? Bool, true)
    }
}
