//
//  SettingsView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedThemeRawValue: String = AppTheme.branco.rawValue

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tema")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.textSecondary)

                HStack(spacing: 14) {
                    ForEach(AppTheme.allCases) { option in
                        Button {
                            selectedThemeRawValue = option.rawValue
                        } label: {
                            Circle()
                                .fill(option.swatchPreview)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Circle().stroke(theme.textSecondary.opacity(0.3), lineWidth: 1)
                                }
                                .overlay {
                                    if option == theme {
                                        Circle().stroke(theme.accent, lineWidth: 2).padding(-3)
                                    }
                                }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(theme.background)
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Pronto") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
