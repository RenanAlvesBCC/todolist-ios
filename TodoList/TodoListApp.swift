//
//  TodoListApp.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

@main
struct TodoListApp: App {
    private let apiClient = APIClient()
    @State private var authViewModel: AuthViewModel
    @State private var taskViewModel: TaskViewModel
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = AppTheme.branco.rawValue

    init() {
        _authViewModel = State(initialValue: AuthViewModel(apiClient: apiClient))
        _taskViewModel = State(initialValue: TaskViewModel(apiClient: apiClient))
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRawValue) ?? .branco
    }

    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel, taskViewModel: taskViewModel)
                .environment(\.appTheme, selectedTheme)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
    }
}
