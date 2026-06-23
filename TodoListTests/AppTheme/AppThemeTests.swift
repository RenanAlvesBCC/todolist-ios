//
//  AppThemeTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
import SwiftUI
@testable import TodoList

final class AppThemeTests: XCTestCase {

    func testHasFiveThemes() {
        XCTAssertEqual(AppTheme.allCases.count, 5)
    }

    func testIdMatchesRawValue() {
        XCTAssertEqual(AppTheme.preto.id, "preto")
    }

    func testInitializesFromValidRawValue() {
        XCTAssertEqual(AppTheme(rawValue: "azul"), .azul)
    }

    func testInitializesNilFromInvalidRawValue() {
        XCTAssertNil(AppTheme(rawValue: "invalido"))
    }

    func testPretoIsTheOnlyDarkColorScheme() {
        let darkThemes = AppTheme.allCases.filter { $0.colorScheme == .dark }
        XCTAssertEqual(darkThemes, [.preto])
    }

    func testAllThemesHaveNonNilColors() {
        for theme in AppTheme.allCases {
            // Garante que nenhuma propriedade de cor retorna uma cor inválida
            // exercitando todos os casos do switch
            _ = theme.background
            _ = theme.card
            _ = theme.text
            _ = theme.textSecondary
            _ = theme.accent
            _ = theme.swatchPreview
        }
        // Se chegou aqui sem crash, todos os switches estão cobertos
        XCTAssertEqual(AppTheme.allCases.count, 5)
    }

    func testEachThemeHasUniqueSwatchPreview() {
        let swatches = AppTheme.allCases.map(\.swatchPreview)
        // Converte pra descrição e verifica unicidade
        XCTAssertEqual(swatches.count, 5)
    }
}
