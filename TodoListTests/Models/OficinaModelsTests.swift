//
//  OficinaModelsTests.swift
//  TodoListTests
//

import XCTest
@testable import TodoList

@MainActor
final class OficinaModelsTests: XCTestCase {

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    func testVehicleStatusRawValuesRoundTrip() throws {
        for status in VehicleStatus.allCases {
            let data = try encoder.encode(status)
            let decoded = try decoder.decode(VehicleStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testVehicleStatusDecodesSnakeCase() throws {
        XCTAssertEqual(try decoder.decode(VehicleStatus.self, from: Data(#""em_andamento""#.utf8)), .emAndamento)
        XCTAssertEqual(try decoder.decode(VehicleStatus.self, from: Data(#""aguardando_orcamento""#.utf8)), .aguardandoOrcamento)
        XCTAssertEqual(try decoder.decode(VehicleStatus.self, from: Data(#""aguardando_peca""#.utf8)), .aguardandoPeca)
        XCTAssertEqual(try decoder.decode(VehicleStatus.self, from: Data(#""aprovado""#.utf8)), .aprovado)
        XCTAssertEqual(try decoder.decode(VehicleStatus.self, from: Data(#""concluido""#.utf8)), .concluido)
    }

    func testVehicleStatusLabelKeys() {
        XCTAssertEqual(VehicleStatus.emAndamento.labelKey, "status.em_andamento")
        XCTAssertEqual(VehicleStatus.aguardandoOrcamento.labelKey, "status.aguardando_orcamento")
        XCTAssertEqual(VehicleStatus.aguardandoPeca.labelKey, "status.aguardando_peca")
        XCTAssertEqual(VehicleStatus.aprovado.labelKey, "status.aprovado")
        XCTAssertEqual(VehicleStatus.concluido.labelKey, "status.concluido")
    }

    func testMechanicTransitionsExcludeApprovalAndDone() {
        XCTAssertEqual(
            VehicleStatus.mechanicTransitions,
            [.emAndamento, .aguardandoOrcamento, .aguardandoPeca]
        )
        XCTAssertFalse(VehicleStatus.mechanicTransitions.contains(.aprovado))
        XCTAssertFalse(VehicleStatus.mechanicTransitions.contains(.concluido))
    }

    func testWorkspaceRoleDisplayNamesAreDistinctAndNonEmpty() {
        let names = [WorkspaceRole.owner, .manager, .editor].map(\.displayName)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(names).count, 3)
    }

    func testDecodesWorkspaceWithSnakeCaseOwnerID() throws {
        let json = """
        {"id":1,"name":"Oficina Centro","description":"Pátio","owner_id":9,"role":"editor"}
        """.data(using: .utf8)!

        let workspace = try decoder.decode(Workspace.self, from: json)

        XCTAssertEqual(workspace.id, 1)
        XCTAssertEqual(workspace.name, "Oficina Centro")
        XCTAssertEqual(workspace.description, "Pátio")
        XCTAssertEqual(workspace.ownerID, 9)
        XCTAssertEqual(workspace.role, .editor)
    }

    func testEncodesWorkspaceWithOwnerIDKey() throws {
        let workspace = Workspace(id: 2, name: "Norte", description: "", ownerID: 4, role: .manager)
        let json = try JSONSerialization.jsonObject(with: encoder.encode(workspace)) as? [String: Any]
        XCTAssertEqual(json?["owner_id"] as? Int, 4)
        XCTAssertEqual(json?["role"] as? String, "manager")
    }

    func testDecodesAndEncodesListAssignment() throws {
        let json = """
        {"id":3,"task_list_id":10,"user_id":5,"assigned_by":1,"assigned_at":"2026-06-18T10:00:00Z"}
        """.data(using: .utf8)!

        let assignment = try decoder.decode(ListAssignment.self, from: json)
        XCTAssertEqual(assignment.id, 3)
        XCTAssertEqual(assignment.taskListID, 10)
        XCTAssertEqual(assignment.userID, 5)
        XCTAssertEqual(assignment.assignedBy, 1)
        XCTAssertNotNil(assignment.assignedAt)

        let encoded = try JSONSerialization.jsonObject(with: encoder.encode(assignment)) as? [String: Any]
        XCTAssertEqual(encoded?["task_list_id"] as? Int, 10)
        XCTAssertEqual(encoded?["assigned_by"] as? Int, 1)
    }

    func testDecodesListAssignmentWithNullAssignedAt() throws {
        let json = """
        {"id":1,"task_list_id":1,"user_id":2,"assigned_by":1,"assigned_at":null}
        """.data(using: .utf8)!

        let assignment = try decoder.decode(ListAssignment.self, from: json)
        XCTAssertNil(assignment.assignedAt)
    }

    func testDecodesAndEncodesQuoteItem() throws {
        let json = """
        {"id":8,"task_list_id":1,"submitted_by":2,"text":"Pastilha","created_at":"2026-06-18T10:00:00Z"}
        """.data(using: .utf8)!

        let quote = try decoder.decode(QuoteItem.self, from: json)
        XCTAssertEqual(quote.id, 8)
        XCTAssertEqual(quote.taskListID, 1)
        XCTAssertEqual(quote.submittedBy, 2)
        XCTAssertEqual(quote.text, "Pastilha")
        XCTAssertNotNil(quote.createdAt)

        let encoded = try JSONSerialization.jsonObject(with: encoder.encode(quote)) as? [String: Any]
        XCTAssertEqual(encoded?["submitted_by"] as? Int, 2)
        XCTAssertEqual(encoded?["task_list_id"] as? Int, 1)
    }

    func testDecodesAndEncodesPendingFlag() throws {
        let json = """
        {
            "id":4,
            "task_list_id":1,
            "created_by":2,
            "flag_type":"procurando_peca",
            "note":"disco",
            "resolved_at":null,
            "resolved_by":null,
            "created_at":"2026-06-18T10:00:00Z"
        }
        """.data(using: .utf8)!

        let flag = try decoder.decode(PendingFlag.self, from: json)
        XCTAssertEqual(flag.id, 4)
        XCTAssertEqual(flag.flagType, "procurando_peca")
        XCTAssertEqual(flag.note, "disco")
        XCTAssertNil(flag.resolvedAt)
        XCTAssertNil(flag.resolvedBy)

        let encoded = try JSONSerialization.jsonObject(with: encoder.encode(flag)) as? [String: Any]
        XCTAssertEqual(encoded?["flag_type"] as? String, "procurando_peca")
        XCTAssertEqual(encoded?["created_by"] as? Int, 2)
    }

    func testEncodesChangeStatusInput() throws {
        let data = try encoder.encode(ChangeStatusInput(status: VehicleStatus.aguardandoPeca.rawValue))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["status"], "aguardando_peca")
    }

    func testEncodesCreateQuoteInput() throws {
        let data = try encoder.encode(CreateQuoteInput(text: "Filtro de óleo"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["text"], "Filtro de óleo")
    }

    func testEncodesCreateFlagInputWithSnakeCaseKey() throws {
        let data = try encoder.encode(CreateFlagInput(flagType: "aguardando_cliente", note: "ligou"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]
        XCTAssertEqual(json?["flag_type"], "aguardando_cliente")
        XCTAssertEqual(json?["note"], "ligou")
    }

    func testWorkspaceRoleDecodesAllCases() throws {
        XCTAssertEqual(try decoder.decode(WorkspaceRole.self, from: Data(#""owner""#.utf8)), .owner)
        XCTAssertEqual(try decoder.decode(WorkspaceRole.self, from: Data(#""manager""#.utf8)), .manager)
        XCTAssertEqual(try decoder.decode(WorkspaceRole.self, from: Data(#""editor""#.utf8)), .editor)
    }
}
