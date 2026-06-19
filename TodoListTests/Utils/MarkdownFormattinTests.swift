//
//  MarkdownFormattinTests.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import XCTest
@testable import TodoList

final class MarkdownFormattingTests: XCTestCase {
    func testWrapsPlainTextInBoldMarkers() {
        XCTAssertEqual(MarkdownFormatting.toggling("Leite", marker: "**"), "**Leite**")
    }

    func testRemovesBoldMarkersWhenAlreadyWrapped() {
        XCTAssertEqual(MarkdownFormatting.toggling("**Leite**", marker: "**"), "Leite")
    }

    func testWrapsInItalicMarkers() {
        XCTAssertEqual(MarkdownFormatting.toggling("Pão", marker: "*"), "*Pão*")
    }

    func testTrimsWhitespaceBeforeWrapping() {
        XCTAssertEqual(MarkdownFormatting.toggling("  Leite  ", marker: "**"), "**Leite**")
    }
}
