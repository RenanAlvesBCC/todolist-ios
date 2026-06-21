//
//  AppTheme.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case branco, preto, bege, azul, cinza

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        self == .preto ? .dark : .light
    }
    
    var background: Color {
        switch self {
        case .branco: return Color(hex: 0xFFFFFF)
        case .preto: return Color(hex: 0x161616)
        case .bege: return Color(hex: 0xF5F0E6)
        case .azul: return Color(hex: 0xEAF2FB)
        case .cinza: return Color(hex: 0xF1EFE8)
        }
    }

    var card: Color {
        switch self {
        case .branco: return Color(hex: 0xF7F6F3)
        case .preto: return Color(hex: 0x262626)
        case .bege, .azul, .cinza: return Color(hex: 0xFFFFFF)
        }
    }

    var text: Color {
        switch self {
        case .branco: return Color(hex: 0x1C1C1E)
        case .preto: return Color(hex: 0xF5F5F5)
        case .bege: return Color(hex: 0x3A3530)
        case .azul: return Color(hex: 0x0C447C)
        case .cinza: return Color(hex: 0x2C2C2A)
        }
    }

    var textSecondary: Color {
        switch self {
        case .branco: return Color(hex: 0x6B6B6B)
        case .preto: return Color(hex: 0xA0A0A0)
        case .bege: return Color(hex: 0x8A8276)
        case .azul: return Color(hex: 0x5B86AD)
        case .cinza: return Color(hex: 0x5F5E5A)
        }
    }

    var accent: Color {
        switch self {
        case .branco: return Color(hex: 0x1C1C1E)
        case .preto: return Color(hex: 0xF5F5F5)
        case .bege: return Color(hex: 0x8A6D3B)
        case .azul: return Color(hex: 0x185FA5)
        case .cinza: return Color(hex: 0x444441)
        }
    }

    var swatchPreview: Color {
        switch self {
        case .branco: return Color(hex: 0xFFFFFF)
        case .preto: return Color(hex: 0x1C1C1E)
        case .bege: return Color(hex: 0xEDE2CF)
        case .azul: return Color(hex: 0x85B7EB)
        case .cinza: return Color(hex: 0xB4B2A9)
        }
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .branco
}
