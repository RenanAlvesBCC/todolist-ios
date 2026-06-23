//
//  BiometricAuthView.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import SwiftUI

struct BiometricAuthView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "faceid")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(theme.textSecondary)

            Text("app.title")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}
