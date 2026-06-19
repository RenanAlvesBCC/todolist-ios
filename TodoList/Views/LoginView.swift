//
//  LoginView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct LoginView: View {
    let viewModel: AuthViewModel

    @Environment(\.appTheme) private var theme
    @State private var username = ""
    @State private var password = ""
    @State private var isRegisterMode = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.text)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "checklist")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(theme.background)
                    }

                Text("To-do list")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)

                Text(isRegisterMode ? "Crie sua conta" : "Entre na sua conta")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
            }

            VStack(spacing: 12) {
                TextField("Usuário", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(theme.card)
                    .foregroundStyle(theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Senha", text: $password)
                    .padding(14)
                    .background(theme.card)
                    .foregroundStyle(theme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await submit() }
            } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(theme.background)
                    } else {
                        Text(isRegisterMode ? "Criar conta" : "Entrar")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
            }
            .background(theme.text)
            .foregroundStyle(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(viewModel.isLoading)

            Button {
                isRegisterMode.toggle()
                viewModel.errorMessage = nil
            } label: {
                Text(isRegisterMode ? "Já tem conta? Entrar" : "Não tem conta? Criar conta")
                    .font(.footnote)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    private func submit() async {
        if isRegisterMode {
            await viewModel.registerAndLogin(username: username, password: password)
        } else {
            await viewModel.login(username: username, password: password)
        }
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
        .environment(\.appTheme, .branco)
}
