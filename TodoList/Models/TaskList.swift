//
//  TaskList.swift
//  TodoList
//

import Foundation

struct TaskList: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    var title: String
    let userID: Int
    var position: Int
    var items: [TaskItem]
    var status: VehicleStatus
    var workspaceID: Int?
    var assignments: [ListAssignment]

    enum CodingKeys: String, CodingKey {
        case id, ID
        case createdAt, CreatedAt
        case updatedAt, UpdatedAt
        case title
        case userID = "user_id"
        case position
        case items
        case status
        case workspaceID = "workspace_id"
        case assignments
    }

    init(
        id: Int,
        createdAt: Date,
        updatedAt: Date,
        title: String,
        userID: Int,
        position: Int,
        items: [TaskItem],
        status: VehicleStatus = .emAndamento,
        workspaceID: Int? = nil,
        assignments: [ListAssignment] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.userID = userID
        self.position = position
        self.items = items
        self.status = status
        self.workspaceID = workspaceID
        self.assignments = assignments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try Self.decodeID(c)
        createdAt = try Self.decodeDate(c, modern: .createdAt, legacy: .CreatedAt)
        updatedAt = try Self.decodeDate(c, modern: .updatedAt, legacy: .UpdatedAt)
        title = try c.decode(String.self, forKey: .title)
        userID = try c.decode(Int.self, forKey: .userID)
        position = try c.decodeIfPresent(Int.self, forKey: .position) ?? 0
        items = try c.decodeIfPresent([TaskItem].self, forKey: .items) ?? []
        status = try c.decodeIfPresent(VehicleStatus.self, forKey: .status) ?? .emAndamento
        workspaceID = try c.decodeIfPresent(Int.self, forKey: .workspaceID)
        assignments = try c.decodeIfPresent([ListAssignment].self, forKey: .assignments) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(title, forKey: .title)
        try c.encode(userID, forKey: .userID)
        try c.encode(position, forKey: .position)
        try c.encode(items, forKey: .items)
        try c.encode(status, forKey: .status)
        try c.encodeIfPresent(workspaceID, forKey: .workspaceID)
        try c.encode(assignments, forKey: .assignments)
    }

    private static func decodeID(_ c: KeyedDecodingContainer<CodingKeys>) throws -> Int {
        if let value = try c.decodeIfPresent(Int.self, forKey: .id) { return value }
        if let value = try c.decodeIfPresent(Int.self, forKey: .ID) { return value }
        throw DecodingError.keyNotFound(
            CodingKeys.id,
            .init(codingPath: c.codingPath, debugDescription: "id")
        )
    }

    private static func decodeDate(
        _ c: KeyedDecodingContainer<CodingKeys>,
        modern: CodingKeys,
        legacy: CodingKeys
    ) throws -> Date {
        if let value = try c.decodeIfPresent(Date.self, forKey: modern) { return value }
        if let value = try c.decodeIfPresent(Date.self, forKey: legacy) { return value }
        return Date()
    }
}
