//
//  AttributeStringMarkdownTests.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import XCTest
import SwiftUI
@testable import TodoList

final class AttributedStringMarkdownTests: XCTestCase {

    func testParsesPlainText() {
        let result = AttributedString(storedMarkdown: "Leite")
        XCTAssertEqual(String(result.characters), "Leite")
    }

    func testParsesBold() {
        let result = AttributedString(storedMarkdown: "**Leite**")
        XCTAssertEqual(String(result.characters), "Leite")
    }

    func testParsesItalic() {
        let result = AttributedString(storedMarkdown: "*Pão*")
        XCTAssertEqual(String(result.characters), "Pão")
    }

    func testParsesBoldAndItalic() {
        let result = AttributedString(storedMarkdown: "***Ovos***")
        XCTAssertEqual(String(result.characters), "Ovos")
    }

    func testParsesPlainTextWithNoMarkdown() {
        let result = AttributedString(storedMarkdown: "Texto simples sem marcação")
        XCTAssertEqual(String(result.characters), "Texto simples sem marcação")
    }

    func testParsesMalformedMarkdownWithoutCrashing() {
        let result = AttributedString(storedMarkdown: "**sem fechar")
        XCTAssertFalse(String(result.characters).isEmpty)
    }

    func testParsesEmptyString() {
        let result = AttributedString(storedMarkdown: "")
        XCTAssertEqual(String(result.characters), "")
    }
}
