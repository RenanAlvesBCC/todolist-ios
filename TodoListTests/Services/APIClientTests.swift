//
//  APIClientTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MockURLSession: URLSessionProtocol {
    var dataToReturn = Data()
    var statusCode = 200
    var lastRequest: URLRequest?
    private(set) var requests: [URLRequest] = []
    private var responseQueue: [(data: Data, statusCode: Int)] = []
    var nonHTTPResponse: URLResponse?

    func enqueue(data: Data, statusCode: Int = 200) {
        responseQueue.append((data, statusCode))
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        requests.append(request)

        if let nonHTTPResponse {
            return (dataToReturn, nonHTTPResponse)
        }

        let (responseData, code): (Data, Int)
        if !responseQueue.isEmpty {
            (responseData, code) = responseQueue.removeFirst()
        } else {
            (responseData, code) = (dataToReturn, statusCode)
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}

final class APIClientTests: XCTestCase {

    func testLoginSuccessReturnsAndStoresToken() async throws {
        let mock = MockURLSession()
        mock.dataToReturn = #"{"token":"eyJhbGciOiJIUzI1NiIs..."}"#.data(using: .utf8)!
        mock.statusCode = 200

        let client = APIClient(session: mock)
        let response = try await client.login(username: "renan", password: "senha123")

        XCTAssertEqual(response.token, "eyJhbGciOiJIUzI1NiIs...")
        XCTAssertEqual(client.token, "eyJhbGciOiJIUzI1NiIs...")
        XCTAssertEqual(mock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mock.lastRequest?.url?.path, "/login")
    }

    func testLoginFailureThrowsServerErrorWithMessage() async {
        let mock = MockURLSession()
        mock.dataToReturn = #"{"error":"usuário ou senha incorretos"}"#.data(using: .utf8)!
        mock.statusCode = 401

        let client = APIClient(session: mock)

        do {
            _ = try await client.login(username: "renan", password: "errada")
            XCTFail("Era esperado um erro, mas o login não lançou nada")
        } catch APIError.server(let message) {
            XCTAssertEqual(message, "usuário ou senha incorretos")
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }
    
    func testFetchListsThrowsWhenNotAuthenticated() async {
        let mock = MockURLSession()
        let client = APIClient(session: mock)

        do {
            _ = try await client.fetchLists(search: "", page: 1, limit: 20, status: nil, mine: false)
            XCTFail("Era esperado um erro de autenticação")
        } catch APIError.notAuthenticated {
            // esperado
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testFetchListsSendsTokenAndQueryParameters() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"lists":[],"page":1,"limit":20,"total":0,"total_pages":0}"#.data(using: .utf8)!)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        _ = try await client.fetchLists(search: "compras", page: 2, limit: 5, status: nil, mine: true)

        let listRequest = mock.requests.last
        XCTAssertEqual(listRequest?.httpMethod, "GET")
        XCTAssertEqual(listRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer fake-token")

        let query = listRequest?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        XCTAssertTrue(query?.contains(URLQueryItem(name: "search", value: "compras")) ?? false)
        XCTAssertTrue(query?.contains(URLQueryItem(name: "page", value: "2")) ?? false)
        XCTAssertTrue(query?.contains(URLQueryItem(name: "mine", value: "true")) ?? false)
    }

    func testCreateListSendsPostAndReturnsDecodedList() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"ID":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Compras da semana","user_id":1,"items":[]}"#.data(using: .utf8)!, statusCode: 201)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        let list = try await client.createList(title: "Compras da semana")

        XCTAssertEqual(list.title, "Compras da semana")
        XCTAssertEqual(mock.requests.last?.httpMethod, "POST")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists")
    }

    func testAddItemSendsPostAndReturnsDecodedItem() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"ID":10,"CreatedAt":"2026-06-18T10:05:00Z","UpdatedAt":"2026-06-18T10:05:00Z","text":"Leite","completed":false,"task_list_id":1}"#.data(using: .utf8)!, statusCode: 201)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        let item = try await client.addItem(listID: 1, text: "Leite")

        XCTAssertEqual(item.text, "Leite")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/1/items")
    }

    func testDeleteListSucceedsOn204NoContent() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        try await client.deleteList(id: 1)

        XCTAssertEqual(mock.requests.last?.httpMethod, "DELETE")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/1")
    }
    
    func testReorderListsSendsPutWithIDs() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        try await client.reorderLists(ids: [3, 1, 2])

        let request = mock.requests.last
        XCTAssertEqual(request?.httpMethod, "PUT")
        XCTAssertEqual(request?.url?.path, "/api/lists/reorder")

        let decoded = try JSONDecoder().decode(ReorderInput.self, from: request!.httpBody!)
        XCTAssertEqual(decoded.ids, [3, 1, 2])
    }
    
    func testReorderItemsSendsPutToCorrectPath() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        try await client.reorderItems(listID: 5, ids: [2, 1])

        XCTAssertEqual(mock.requests.last?.httpMethod, "PUT")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/5/items/reorder")

        let decoded = try JSONDecoder().decode(ReorderInput.self, from: mock.requests.last!.httpBody!)
        XCTAssertEqual(decoded.ids, [2, 1])
    }

    func testUpdateListSendsPutWithTitle() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"ID":1,"CreatedAt":"2026-06-18T10:00:00Z","UpdatedAt":"2026-06-18T10:00:00Z","title":"Novo título","user_id":1,"items":[]}"#.data(using: .utf8)!)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        let list = try await client.updateList(id: 1, title: "Novo título")

        XCTAssertEqual(list.title, "Novo título")
        XCTAssertEqual(mock.requests.last?.httpMethod, "PUT")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/1")
    }

    func testUpdateItemSendsPutToCorrectPath() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"ID":10,"CreatedAt":"2026-06-18T10:05:00Z","UpdatedAt":"2026-06-18T10:05:00Z","text":"Leite desnatado","completed":true,"task_list_id":1}"#.data(using: .utf8)!)

        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")
        let item = try await client.updateItem(listID: 1, itemID: 10, text: "Leite desnatado", completed: true)

        XCTAssertEqual(item.text, "Leite desnatado")
        XCTAssertTrue(item.completed)
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/1/items/10")
    }

    func testRegisterSendsPostAndReturnsMessage() async throws {
        let mock = MockURLSession()
        mock.dataToReturn = #"{"message":"usuário criado com sucesso"}"#.data(using: .utf8)!
        mock.statusCode = 201

        let client = APIClient(session: mock)
        let response = try await client.register(username: "renan", password: "senha123")

        XCTAssertEqual(response.message, "usuário criado com sucesso")
        XCTAssertEqual(mock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mock.lastRequest?.url?.path, "/register")
    }

    func testRestoreTokenAllowsAuthenticatedRequests() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"lists":[],"page":1,"limit":20,"total":0,"total_pages":0}"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        client.restoreToken("restored-token")

        _ = try await client.fetchLists(search: "", page: 1, limit: 20, status: nil, mine: false)

        XCTAssertEqual(mock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer restored-token")
    }

    func testLogoutClearsTokenOnSuccess() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        try await client.logout()

        XCTAssertNil(client.token)
        XCTAssertEqual(mock.requests.last?.httpMethod, "POST")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/logout")
    }

    func testLogoutClearsTokenEvenWhenServerFails() async {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"error":"token inválido"}"#.data(using: .utf8)!, statusCode: 401)
        let client = APIClient(session: mock)
        _ = try? await client.login(username: "renan", password: "senha123")

        do {
            try await client.logout()
            XCTFail("Era esperado um erro")
        } catch APIError.server {
            XCTAssertNil(client.token)
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testLogoutThrowsWhenNotAuthenticated() async {
        let client = APIClient(session: MockURLSession())
        do {
            try await client.logout()
            XCTFail("Era esperado não autenticado")
        } catch APIError.notAuthenticated {
            XCTAssertNil(client.token)
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testFetchListsIncludesStatusAndOmitsEmptySearch() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"lists":[],"page":1,"limit":20,"total":0,"total_pages":0}"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        _ = try await client.fetchLists(search: "", page: 1, limit: 20, status: "em_andamento", mine: false)

        let query = mock.requests.last?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        XCTAssertTrue(query?.contains(URLQueryItem(name: "status", value: "em_andamento")) ?? false)
        XCTAssertFalse(query?.contains { $0.name == "search" } ?? true)
        XCTAssertFalse(query?.contains { $0.name == "mine" } ?? true)
    }

    func testFetchListsIgnoresEmptyStatus() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"lists":[],"page":1,"limit":20,"total":0,"total_pages":0}"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        _ = try await client.fetchLists(search: "", page: 1, limit: 20, status: "", mine: false)

        let query = mock.requests.last?.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
        XCTAssertFalse(query?.contains { $0.name == "status" } ?? true)
    }

    func testDeleteItemSucceedsOn204() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        try await client.deleteItem(listID: 3, itemID: 9)

        XCTAssertEqual(mock.requests.last?.httpMethod, "DELETE")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/3/items/9")
    }

    func testChangeStatusSendsPutWithStatusBody() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        try await client.changeStatus(listID: 4, status: .aguardandoPeca)

        XCTAssertEqual(mock.requests.last?.httpMethod, "PUT")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/4/status")
        let decoded = try JSONDecoder().decode(ChangeStatusInput.self, from: mock.requests.last!.httpBody!)
        XCTAssertEqual(decoded.status, "aguardando_peca")
    }

    func testFetchQuotesDecodesArray() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"[{"id":1,"task_list_id":2,"submitted_by":3,"text":"Pastilha","created_at":"2026-06-18T10:00:00Z"}]"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        let quotes = try await client.fetchQuotes(listID: 2)

        XCTAssertEqual(quotes.first?.text, "Pastilha")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/2/quotes")
    }

    func testAddQuoteSendsPostAndReturnsItem() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"id":1,"task_list_id":2,"submitted_by":3,"text":"Filtro","created_at":"2026-06-18T10:00:00Z"}"#.data(using: .utf8)!, statusCode: 201)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        let quote = try await client.addQuote(listID: 2, text: "Filtro")

        XCTAssertEqual(quote.text, "Filtro")
        XCTAssertEqual(mock.requests.last?.httpMethod, "POST")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/2/quotes")
    }

    func testFetchFlagsDecodesArray() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"[{"id":1,"task_list_id":2,"created_by":3,"flag_type":"procurando_peca","note":"","resolved_at":null,"resolved_by":null,"created_at":"2026-06-18T10:00:00Z"}]"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        let flags = try await client.fetchFlags(listID: 2)

        XCTAssertEqual(flags.first?.flagType, "procurando_peca")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/2/flags")
    }

    func testAddFlagSendsFlagTypeInBody() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"id":1,"task_list_id":2,"created_by":3,"flag_type":"aguardando_cliente","note":"ligou","resolved_at":null,"resolved_by":null,"created_at":"2026-06-18T10:00:00Z"}"#.data(using: .utf8)!, statusCode: 201)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        let flag = try await client.addFlag(listID: 2, flagType: "aguardando_cliente", note: "ligou")

        XCTAssertEqual(flag.flagType, "aguardando_cliente")
        let decoded = try JSONDecoder().decode(CreateFlagInput.self, from: mock.requests.last!.httpBody!)
        XCTAssertEqual(decoded.flagType, "aguardando_cliente")
        XCTAssertEqual(decoded.note, "ligou")
    }

    func testResolveFlagSendsPatch() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        try await client.resolveFlag(listID: 2, flagID: 8)

        XCTAssertEqual(mock.requests.last?.httpMethod, "PATCH")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/lists/2/flags/8/resolve")
    }

    func testFetchWorkspaceDecodesRole() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: #"{"id":1,"name":"Oficina Centro","description":"","owner_id":9,"role":"editor"}"#.data(using: .utf8)!)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        let workspace = try await client.fetchWorkspace()

        XCTAssertEqual(workspace.name, "Oficina Centro")
        XCTAssertEqual(workspace.role, .editor)
        XCTAssertEqual(workspace.ownerID, 9)
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/workspace")
    }

    func testAcceptInviteSendsPost() async throws {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 204)
        let client = APIClient(session: mock)
        _ = try await client.login(username: "renan", password: "senha123")

        try await client.acceptInvite(code: "ABC123")

        XCTAssertEqual(mock.requests.last?.httpMethod, "POST")
        XCTAssertEqual(mock.requests.last?.url?.path, "/api/invites/ABC123/accept")
    }

    func testInvalidJSONThrowsDecodingError() async {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data("não é json".utf8))
        let client = APIClient(session: mock)
        _ = try? await client.login(username: "renan", password: "senha123")

        do {
            _ = try await client.fetchWorkspace()
            XCTFail("Era esperado erro de decoding")
        } catch APIError.decoding {
            // esperado
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testNonJSONServerErrorThrowsInvalidResponse() async {
        let mock = MockURLSession()
        mock.enqueue(data: #"{"token":"fake-token"}"#.data(using: .utf8)!)
        mock.enqueue(data: Data(), statusCode: 500)
        let client = APIClient(session: mock)
        _ = try? await client.login(username: "renan", password: "senha123")

        do {
            _ = try await client.fetchWorkspace()
            XCTFail("Era esperado invalidResponse")
        } catch APIError.invalidResponse {
            // esperado
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }

    func testNonHTTPResponseThrowsInvalidResponse() async {
        let mock = MockURLSession()
        mock.nonHTTPResponse = URLResponse()
        let client = APIClient(session: mock)

        do {
            _ = try await client.login(username: "renan", password: "senha123")
            XCTFail("Era esperado invalidResponse")
        } catch APIError.invalidResponse {
            // esperado
        } catch {
            XCTFail("Tipo de erro inesperado: \(error)")
        }
    }
}
