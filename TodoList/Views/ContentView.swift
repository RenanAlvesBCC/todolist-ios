//
//  ContentView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct ContentView: View {
    let authViewModel: AuthViewModel
    let taskViewModel: TaskViewModel

    var body: some View {
        switch authViewModel.state {
        case .signedOut:
            LoginView(viewModel: authViewModel)
        case .signedIn:
            TaskGridView(authViewModel: authViewModel, taskViewModel: taskViewModel)
        }
    }
}

#Preview {
    let client = APIClient()
    return ContentView(authViewModel: AuthViewModel(apiClient: client), taskViewModel: TaskViewModel(apiClient: client))
}
