//
//  ContentView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct ContentView: View {
    let authViewModel: AuthViewModel

    var body: some View {
        switch authViewModel.state {
        case .signedOut:
            LoginView(viewModel: authViewModel)
        case .signedIn:
            SignedInPlaceholderView(viewModel: authViewModel)
        }
    }
}

private struct SignedInPlaceholderView: View {
    let viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Login realizado com sucesso 🎉")
                .font(.headline)
            Text("A grade de tarefas chega na próxima fase.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            Button("Sair", role: .destructive) {
                viewModel.logout()
            }
            .padding(.top)
        }
        .padding()
    }
}

#Preview {
    ContentView(authViewModel: AuthViewModel())
}
