//
//  TaskViewModel+OficinaTests.swift
//  TodoListTests
//

import XCTest
@testable import TodoList

private struct DummyError: Error {}

@MainActor
final class TaskViewModelOficinaTests: XCTestCase {

    private func loadedViewModel(
        lists: [TaskList] = [.stub(id: 1)],
        api: MockTaskAPIClient = MockTaskAPIClient(),
        cache: MockCacheService = MockCacheService(),
        sync: MockSyncService = MockSyncService()
    ) async -> (TaskViewModel, MockTaskAPIClient) {
        api.fetchListsResult = .success(
            TaskListResponse(lists: lists, page: 1, limit: 100, total: lists.count, totalPages: 1)
        )
        let viewModel = TaskViewModel.makeForTesting(apiClient: api, cacheService: cache, syncService: sync)
        await viewModel.loadLists()
        return (viewModel, api)
    }

    func testSyncPendingOperationsProcessesQueueAndReloads() async {
        let api = MockTaskAPIClient()
        api.fetchListsResult = .success(TaskListResponse(lists: [.stub(id: 1)], page: 1, limit: 100, total: 1, totalPages: 1))
        let sync = MockSyncService()
        sync.hasPendingOperations = true
        let viewModel = TaskViewModel.makeForTesting(apiClient: api, syncService: sync)

        await viewModel.syncPendingOperations()

        XCTAssertEqual(sync.processCallCount, 1)
        XCTAssertEqual(api.fetchListsCallCount, 1)
        XCTAssertFalse(viewModel.hasPendingSync)
    }

    func testSyncPendingOperationsDoesNothingWhenQueueIsEmpty() async {
        let api = MockTaskAPIClient()
        let sync = MockSyncService()
        let viewModel = TaskViewModel.makeForTesting(apiClient: api, syncService: sync)

        await viewModel.syncPendingOperations()

        XCTAssertEqual(sync.processCallCount, 0)
        XCTAssertEqual(api.fetchListsCallCount, 0)
    }

    func testLoadListsKeepsCacheAndOmitsErrorWhenServerFails() async {
        let cache = MockCacheService()
        cache.savedLists = [.stub(id: 1, title: "Civic")]
        let api = MockTaskAPIClient()
        api.fetchListsResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api, cacheService: cache)

        await viewModel.loadLists()

        XCTAssertEqual(viewModel.taskLists.first?.title, "Civic")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadListsUsesLocalizedDescriptionForUnknownError() async {
        let api = MockTaskAPIClient()
        api.fetchListsResult = .failure(DummyError())
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)

        await viewModel.loadLists()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.errorMessage?.isEmpty ?? true)
    }

    func testAddListFailureKeepsTempListAndEnqueues() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)

        await viewModel.addList(title: "Civic")

        XCTAssertEqual(viewModel.taskLists.first?.title, "Civic")
        XCTAssertTrue(viewModel.taskLists.first?.id ?? 0 < 0)
        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testDeleteListWithTempIDDoesNotCallAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")
        let temp = viewModel.taskLists[0]

        await viewModel.deleteList(temp)

        XCTAssertTrue(viewModel.taskLists.isEmpty)
        XCTAssertNil(api.lastDeletedListID)
    }

    func testDeleteListFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.deleteListError = APIError.server(message: "negado")
        let (viewModel, _) = await loadedViewModel(api: api)
        let list = viewModel.taskLists[0]

        await viewModel.deleteList(list)

        XCTAssertTrue(viewModel.taskLists.isEmpty)
        XCTAssertTrue(viewModel.hasPendingSync)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRenameListWithBlankTitleSetsError() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.renameList(viewModel.taskLists[0], title: "   ")

        XCTAssertEqual(viewModel.errorMessage, L10n.Error.titleRequired)
        XCTAssertNil(api.lastUpdateList)
    }

    func testRenameListFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.updateListError = APIError.invalidResponse
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.renameList(viewModel.taskLists[0], title: "Gol")

        XCTAssertEqual(viewModel.taskLists.first?.title, "Gol")
        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testRenameListWithTempIDSkipsAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")

        await viewModel.renameList(viewModel.taskLists[0], title: "Fit")

        XCTAssertEqual(viewModel.taskLists.first?.title, "Fit")
        XCTAssertNil(api.lastUpdateList)
    }

    func testAddItemWithBlankTextSetsError() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.addItem(text: "  ", to: viewModel.taskLists[0])

        XCTAssertEqual(viewModel.errorMessage, L10n.Error.itemTextRequired)
        XCTAssertNil(api.lastAddItem)
    }

    func testAddItemOnTempListEnqueuesWithoutAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")

        await viewModel.addItem(text: "Óleo", to: viewModel.taskLists[0])

        XCTAssertNil(api.lastAddItem)
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.text, "Óleo")
        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testAddItemFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.addItemResult = .failure(APIError.invalidResponse)
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.addItem(text: "Óleo", to: viewModel.taskLists[0])

        XCTAssertTrue(viewModel.hasPendingSync)
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.text, "Óleo")
    }

    func testUpdateItemWithTempIDSkipsAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")
        await viewModel.addItem(text: "Óleo", to: viewModel.taskLists[0])
        let item = viewModel.taskLists[0].items[0]

        await viewModel.updateItem(item, in: viewModel.taskLists[0], text: "Filtro", completed: true)

        XCTAssertNil(api.lastUpdateItemInput)
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.text, "Filtro")
        XCTAssertEqual(viewModel.taskLists.first?.items.first?.completed, true)
    }

    func testUpdateItemFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.updateItemResult = .failure(APIError.invalidResponse)
        let item = TaskItem.stub(id: 5, taskListID: 1)
        let (viewModel, _) = await loadedViewModel(lists: [.stub(id: 1, items: [item])], api: api)

        await viewModel.updateItem(item, in: viewModel.taskLists[0], text: "Novo", completed: true)

        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testDeleteItemWithTempIDSkipsAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")
        await viewModel.addItem(text: "Óleo", to: viewModel.taskLists[0])
        let item = viewModel.taskLists[0].items[0]

        await viewModel.deleteItem(item, from: viewModel.taskLists[0])

        XCTAssertNil(api.lastDeleteItemInput)
        XCTAssertTrue(viewModel.taskLists.first?.items.isEmpty ?? false)
    }

    func testPersistListOrderFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.reorderListsError = APIError.invalidResponse
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.persistListOrder()

        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testPersistItemOrderFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.reorderItemsError = APIError.invalidResponse
        let list = TaskList.stub(id: 1, items: [TaskItem.stub(id: 10)])
        let (viewModel, _) = await loadedViewModel(lists: [list], api: api)

        await viewModel.persistItemOrder(for: viewModel.taskLists[0])

        XCTAssertTrue(viewModel.hasPendingSync)
    }

    func testPersistItemOrderDoesNothingWhenListIsMissing() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.persistItemOrder(for: .stub(id: 999))

        XCTAssertNil(api.reorderItemsInput)
    }

    func testMoveListsIgnoresUnknownOrSameIDs() async {
        let (viewModel, _) = await loadedViewModel(lists: [.stub(id: 1), .stub(id: 2)])
        let original = viewModel.taskLists.map(\.id)

        viewModel.moveLists(fromID: 1, toID: 1)
        viewModel.moveLists(fromID: 9, toID: 1)
        XCTAssertEqual(viewModel.taskLists.map(\.id), original)
    }

    func testMoveItemsIgnoresUnknownOrSameIDs() async {
        let items = [TaskItem.stub(id: 10), TaskItem.stub(id: 11)]
        let (viewModel, _) = await loadedViewModel(lists: [.stub(id: 1, items: items)])

        viewModel.moveItems(in: viewModel.taskLists[0], fromID: 10, toID: 10)
        viewModel.moveItems(in: viewModel.taskLists[0], fromID: 99, toID: 10)
        XCTAssertEqual(viewModel.taskLists.first?.items.map(\.id), [10, 11])
    }

    func testVehiclesByStatusGroupsAndOmitsEmpty() async {
        var andamento = TaskList.stub(id: 1, title: "A")
        andamento.status = .emAndamento
        var peca = TaskList.stub(id: 2, title: "B")
        peca.status = .aguardandoPeca
        var done = TaskList.stub(id: 3, title: "C")
        done.status = .concluido
        let (viewModel, _) = await loadedViewModel(lists: [andamento, peca, done])

        let groups = viewModel.vehiclesByStatus
        XCTAssertEqual(groups.map(\.status), [.emAndamento, .aguardandoPeca, .concluido])
        XCTAssertEqual(groups.first?.vehicles.first?.title, "A")
        XCTAssertFalse(groups.contains { $0.status == .aprovado })
    }

    func testChangeStatusFailureEnqueuesAndSetsError() async {
        let api = MockTaskAPIClient()
        api.changeStatusError = APIError.server(message: "transição negada")
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.changeStatus(viewModel.taskLists[0], to: .aguardandoOrcamento)

        XCTAssertEqual(viewModel.taskLists.first?.status, .aguardandoOrcamento)
        XCTAssertTrue(viewModel.hasPendingSync)
        XCTAssertEqual(viewModel.errorMessage, "transição negada")
    }

    func testChangeStatusWithTempIDSkipsAPI() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")

        await viewModel.changeStatus(viewModel.taskLists[0], to: .aguardandoPeca)

        XCTAssertEqual(viewModel.taskLists.first?.status, .aguardandoPeca)
        XCTAssertNil(api.lastChangeStatus)
    }

    func testLoadVehicleExtrasPopulatesQuotesAndFlags() async {
        let api = MockTaskAPIClient()
        api.fetchQuotesResult = .success([
            QuoteItem(id: 1, taskListID: 1, submittedBy: 1, text: "Pastilha", createdAt: Date())
        ])
        api.fetchFlagsResult = .success([
            PendingFlag(id: 2, taskListID: 1, createdBy: 1, flagType: "procurando_peca", note: "", resolvedAt: nil, resolvedBy: nil, createdAt: Date())
        ])
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.loadVehicleExtras(for: viewModel.taskLists[0])

        XCTAssertEqual(viewModel.quotesByList[1]?.first?.text, "Pastilha")
        XCTAssertEqual(viewModel.flagsByList[1]?.first?.flagType, "procurando_peca")
    }

    func testLoadVehicleExtrasWithTempIDDoesNothing() async {
        let api = MockTaskAPIClient()
        api.createListResult = .failure(APIError.invalidResponse)
        let viewModel = TaskViewModel.makeForTesting(apiClient: api)
        await viewModel.addList(title: "Civic")

        await viewModel.loadVehicleExtras(for: viewModel.taskLists[0])

        XCTAssertTrue(viewModel.quotesByList.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadVehicleExtrasSetsErrorOnFailure() async {
        let api = MockTaskAPIClient()
        api.fetchQuotesResult = .failure(APIError.decoding)
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.loadVehicleExtras(for: viewModel.taskLists[0])

        XCTAssertEqual(viewModel.errorMessage, L10n.Error.unexpectedResponse)
    }

    func testAddQuoteIgnoresBlankText() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.addQuote(text: "   ", to: viewModel.taskLists[0])

        XCTAssertNil(api.lastAddQuote)
        XCTAssertTrue(viewModel.quotesByList.isEmpty)
    }

    func testAddQuoteAppendsCreatedItem() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.addQuote(text: "  Filtro  ", to: viewModel.taskLists[0])

        XCTAssertEqual(api.lastAddQuote?.text, "Filtro")
        XCTAssertEqual(viewModel.quotesByList[1]?.first?.text, "Filtro")
    }

    func testAddQuoteFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.addQuoteError = APIError.invalidResponse
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.addQuote(text: "Filtro", to: viewModel.taskLists[0])

        XCTAssertTrue(viewModel.hasPendingSync)
        XCTAssertEqual(viewModel.errorMessage, L10n.Error.serverUnavailable)
    }

    func testAddFlagAppendsCreatedItem() async {
        let (viewModel, api) = await loadedViewModel()

        await viewModel.addFlag(type: "procurando_peca", note: "disco", to: viewModel.taskLists[0])

        XCTAssertEqual(api.lastAddFlag?.flagType, "procurando_peca")
        XCTAssertEqual(viewModel.flagsByList[1]?.first?.note, "disco")
    }

    func testAddFlagFailureEnqueuesPendingSync() async {
        let api = MockTaskAPIClient()
        api.addFlagError = APIError.invalidResponse
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.addFlag(type: "aguardando_cliente", note: "", to: viewModel.taskLists[0])

        XCTAssertTrue(viewModel.hasPendingSync)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testResolveFlagMarksResolvedLocally() async {
        let flag = PendingFlag(id: 9, taskListID: 1, createdBy: 1, flagType: "procurando_peca", note: "", resolvedAt: nil, resolvedBy: nil, createdAt: Date())
        let other = PendingFlag(id: 8, taskListID: 1, createdBy: 1, flagType: "aguardando_cliente", note: "", resolvedAt: nil, resolvedBy: nil, createdAt: Date())
        let api = MockTaskAPIClient()
        api.fetchFlagsResult = .success([flag, other])
        let (viewModel, _) = await loadedViewModel(api: api)
        await viewModel.loadVehicleExtras(for: viewModel.taskLists[0])

        await viewModel.resolveFlag(flag, in: viewModel.taskLists[0])

        XCTAssertEqual(api.lastResolveFlag?.flagID, 9)
        XCTAssertNotNil(viewModel.flagsByList[1]?.first { $0.id == 9 }?.resolvedAt)
        XCTAssertNil(viewModel.flagsByList[1]?.first { $0.id == 8 }?.resolvedAt)
    }

    func testResolveFlagFailureSetsError() async {
        let flag = PendingFlag(id: 9, taskListID: 1, createdBy: 1, flagType: "procurando_peca", note: "", resolvedAt: nil, resolvedBy: nil, createdAt: Date())
        let api = MockTaskAPIClient()
        api.resolveFlagError = APIError.server(message: "não encontrado")
        let (viewModel, _) = await loadedViewModel(api: api)

        await viewModel.resolveFlag(flag, in: viewModel.taskLists[0])

        XCTAssertEqual(viewModel.errorMessage, "não encontrado")
    }
}
