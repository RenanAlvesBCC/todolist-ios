//
//  TodoListApp.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

@main
struct TodoListApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(authViewModel: authViewModel)
        }
    }
}
