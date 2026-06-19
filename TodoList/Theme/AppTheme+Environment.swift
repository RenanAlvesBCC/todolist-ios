//
//  AppTheme+Environment.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .branco
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
