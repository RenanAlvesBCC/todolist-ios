//
//  ContentView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let authViewModel: AuthViewModel
    let taskViewModel: TaskViewModel

    var body: some View {
        switch authViewModel.state {
        case .signedOut:
            LoginView(viewModel: authViewModel)
        case .authenticating:
            BiometricAuthView()
        case .signedIn:
            TaskGridView(authViewModel: authViewModel, taskViewModel: taskViewModel)
        }
    }
}

#Preview {
    let apiClient = APIClient()
    let config = try! ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: CachedTaskList.self, CachedTaskItem.self, PendingOperation.self,
        configurations: config
    )
    let cacheService = CacheService(modelContext: container.mainContext)
    let syncService = SyncService(
        apiClient: apiClient,
        cacheService: cacheService,
        modelContext: container.mainContext
    )
    ContentView(
        authViewModel: AuthViewModel(apiClient: apiClient),
        taskViewModel: TaskViewModel(
            apiClient: apiClient,
            cacheService: cacheService,
            syncService: syncService
        )
    )
    .modelContainer(container)
}
