import Foundation

enum VehicleStatus: String, Codable, CaseIterable, Hashable {
    case emAndamento = "em_andamento"
    case aguardandoOrcamento = "aguardando_orcamento"
    case aguardandoPeca = "aguardando_peca"
    case aprovado = "aprovado"
    case concluido = "concluido"

    var labelKey: String {
        switch self {
        case .emAndamento: return "status.em_andamento"
        case .aguardandoOrcamento: return "status.aguardando_orcamento"
        case .aguardandoPeca: return "status.aguardando_peca"
        case .aprovado: return "status.aprovado"
        case .concluido: return "status.concluido"
        }
    }

    static var mechanicTransitions: [VehicleStatus] {
        [.emAndamento, .aguardandoOrcamento, .aguardandoPeca]
    }
}

enum WorkspaceRole: String, Codable {
    case owner, manager, editor

    var displayName: String {
        switch self {
        case .owner: return String(localized: "role.owner")
        case .manager: return String(localized: "role.manager")
        case .editor: return String(localized: "role.mechanic")
        }
    }
}

struct Workspace: Codable, Equatable {
    let id: Int
    let name: String
    let description: String
    let ownerID: Int
    let role: WorkspaceRole

    enum CodingKeys: String, CodingKey {
        case id, name, description, role
        case ownerID = "owner_id"
    }
}

struct ListAssignment: Codable, Equatable, Hashable, Identifiable {
    let id: Int
    let taskListID: Int
    let userID: Int
    let assignedBy: Int
    let assignedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case taskListID = "task_list_id"
        case userID = "user_id"
        case assignedBy = "assigned_by"
        case assignedAt = "assigned_at"
    }
}

struct QuoteItem: Codable, Equatable, Identifiable {
    let id: Int
    let taskListID: Int
    let submittedBy: Int
    let text: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, text
        case taskListID = "task_list_id"
        case submittedBy = "submitted_by"
        case createdAt = "created_at"
    }
}

struct PendingFlag: Codable, Equatable, Identifiable {
    let id: Int
    let taskListID: Int
    let createdBy: Int
    let flagType: String
    let note: String
    let resolvedAt: Date?
    let resolvedBy: Int?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, note
        case taskListID = "task_list_id"
        case createdBy = "created_by"
        case flagType = "flag_type"
        case resolvedAt = "resolved_at"
        case resolvedBy = "resolved_by"
        case createdAt = "created_at"
    }
}

struct ChangeStatusInput: Codable {
    let status: String
}

struct CreateQuoteInput: Codable {
    let text: String
}

struct CreateFlagInput: Codable {
    let flagType: String
    let note: String

    enum CodingKeys: String, CodingKey {
        case flagType = "flag_type"
        case note
    }
}

struct AcceptInviteInput: Codable {
    // body vazio; path leva o código
}
