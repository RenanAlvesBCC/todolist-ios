//
//  AppThemeTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
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
}
