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

    init() {
        _authViewModel = State(initialValue: AuthViewModel(apiClient: apiClient))
        _taskViewModel = State(initialValue: TaskViewModel(apiClient: apiClient))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel, taskViewModel: taskViewModel)
        }
    }
}
