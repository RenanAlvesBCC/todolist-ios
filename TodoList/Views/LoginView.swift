//
//  LoginView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct LoginView: View {
    let viewModel: AuthViewModel

    @State private var username = ""
    @State private var password = ""
    @State private var isRegisterMode = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appText)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "checklist")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }

                Text("To-do list")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(isRegisterMode ? "Crie sua conta" : "Entre na sua conta")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }

            VStack(spacing: 12) {
                TextField("Usuário", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Senha", text: $password)
                    .padding(14)
                    .background(Color.appCardBackground)
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
                            .tint(.white)
                    } else {
                        Text(isRegisterMode ? "Criar conta" : "Entrar")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
            }
            .background(Color.appText)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(viewModel.isLoading)

            Button {
                isRegisterMode.toggle()
                viewModel.errorMessage = nil
            } label: {
                Text(isRegisterMode ? "Já tem conta? Entrar" : "Não tem conta? Criar conta")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
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
}
