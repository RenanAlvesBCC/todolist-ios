//
//  TaskViewModel+SearchText.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import XCTest
@testable import TodoList

@MainActor
final class TaskViewModelSearchTests: XCTestCase {

    func testSearchTextEventuallyTriggersLoadWithSearchTerm() async throws {
        let mock = MockTaskAPIClient()
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        viewModel.searchText = "compras"

        try await Task.sleep(for: .milliseconds(600))

        XCTAssertEqual(mock.lastFetchListsSearch, "compras")
    }

    func testRapidTypingOnlySearchesFinalText() async throws {
        let mock = MockTaskAPIClient()
        let viewModel = TaskViewModel.makeForTesting(apiClient: mock)

        viewModel.searchText = "c"
        viewModel.searchText = "co"
        viewModel.searchText = "com"
        viewModel.searchText = "compras"

        try await Task.sleep(for: .milliseconds(600))

        XCTAssertEqual(mock.fetchListsCallCount, 1)
        XCTAssertEqual(mock.lastFetchListsSearch, "compras")
    }
}
