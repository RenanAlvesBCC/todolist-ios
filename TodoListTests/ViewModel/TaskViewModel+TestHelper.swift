//
//  TaskViewModel+TestHelper.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftData
import Foundation
@testable import TodoList

extension TaskViewModel {
    @MainActor
    static func makeForTesting(
        apiClient: TaskAPIClient,
        cacheService: CacheServiceProtocol? = nil,
        syncService: SyncServiceProtocol? = nil
    ) -> TaskViewModel {
        return TaskViewModel(
            apiClient: apiClient,
            cacheService: cacheService ?? MockCacheService(),
            syncService: syncService ?? MockSyncService()
        )
    }
}
