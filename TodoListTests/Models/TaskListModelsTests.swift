//
//  TaskListModelsTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class TaskListModelsTests: XCTestCase {

    func testEncodesCreateListInput() throws {
        let input = CreateListInput(title: "Compras da semana")
        let data = try JSONEncoder().encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["title"], "Compras da semana")
    }

    func testEncodesUpdateItemInputIncludingCompletedFlag() throws {
        let input = UpdateItemInput(text: "Leite desnatado", completed: true)
        let data = try JSONEncoder().encode(input)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["completed"] as? Bool, true)
    }

    func testDecodesTaskListResponse() throws {
        let json = """
        {
            "lists": [
                {"ID":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Compras da semana","user_id":1,"items":[]}
            ],
            "page": 1, "limit": 20, "total": 1, "total_pages": 1
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(TaskListResponse.self, from: json)

        XCTAssertEqual(response.lists.count, 1)
        XCTAssertEqual(response.totalPages, 1)
    }
}
