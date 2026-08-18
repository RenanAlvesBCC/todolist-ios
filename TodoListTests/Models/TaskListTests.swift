//
//  TaskListTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

@MainActor
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

    func testEncodesTaskListWithStatusAndAssignments() throws {
        let assignment = ListAssignment(id: 1, taskListID: 1, userID: 2, assignedBy: 1, assignedAt: nil)
        var list = TaskList.stub(id: 1, title: "Civic", items: [TaskItem.stub(id: 10)])
        list.status = .aguardandoPeca
        list.workspaceID = 3
        list.assignments = [assignment]

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try JSONSerialization.jsonObject(with: encoder.encode(list)) as? [String: Any]
        XCTAssertEqual(json?["status"] as? String, "aguardando_peca")
        XCTAssertEqual(json?["workspace_id"] as? Int, 3)
        XCTAssertEqual((json?["assignments"] as? [[String: Any]])?.count, 1)
    }

    func testDecodesTaskListWithEmptyItemsArray() throws {
        let json = """
        {"ID":2,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Nova lista","user_id":1,"items":[]}
        """.data(using: .utf8)!

        let list = try decoder.decode(TaskList.self, from: json)
        XCTAssertTrue(list.items.isEmpty)
    }

    func testDecodesModernIDAndDateKeysWithStatus() throws {
        let json = """
        {
            "id": 5,
            "createdAt": "2026-06-18T10:00:00Z",
            "updatedAt": "2026-06-18T10:00:00Z",
            "title": "Civic",
            "user_id": 1,
            "position": 2,
            "status": "aguardando_peca",
            "workspace_id": 9,
            "assignments": [
                {"id":1,"task_list_id":5,"user_id":2,"assigned_by":1,"assigned_at":null}
            ],
            "items": []
        }
        """.data(using: .utf8)!

        let list = try decoder.decode(TaskList.self, from: json)
        XCTAssertEqual(list.id, 5)
        XCTAssertEqual(list.status, .aguardandoPeca)
        XCTAssertEqual(list.workspaceID, 9)
        XCTAssertEqual(list.assignments.count, 1)
        XCTAssertEqual(list.position, 2)
    }

    func testDecodeFailsWhenIDIsMissing() {
        let json = """
        {"title":"Sem id","user_id":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z"}
        """.data(using: .utf8)!
        XCTAssertThrowsError(try decoder.decode(TaskList.self, from: json))
    }
}
