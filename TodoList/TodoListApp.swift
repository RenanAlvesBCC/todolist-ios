//
//  TodoListApp.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI
import SwiftData

@main
struct TodoListApp: App {
    private let apiClient = APIClient()
    @State private var authViewModel: AuthViewModel
    @State private var taskViewModel: TaskViewModel
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = AppTheme.branco.rawValue
    @Environment(\.scenePhase) private var scenePhase

    private let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(
            for: CachedTaskList.self, CachedTaskItem.self, PendingOperation.self
        )
        self.modelContainer = container

        let cacheService = CacheService(modelContext: container.mainContext)
        let syncService = SyncService(
            apiClient: apiClient,
            cacheService: cacheService,
            modelContext: container.mainContext
        )

        _authViewModel = State(initialValue: AuthViewModel(apiClient: apiClient))
        _taskViewModel = State(initialValue: TaskViewModel(
            apiClient: apiClient,
            cacheService: cacheService,
            syncService: syncService
        ))
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRawValue) ?? .branco
    }

    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel, taskViewModel: taskViewModel)
                .environment(\.appTheme, selectedTheme)
                .preferredColorScheme(selectedTheme.colorScheme)
                .modelContainer(modelContainer)
                .task {
                    await authViewModel.attemptBiometricLogin()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        Task { await taskViewModel.syncPendingOperations() }
                    }
                }
        }
    }
}
