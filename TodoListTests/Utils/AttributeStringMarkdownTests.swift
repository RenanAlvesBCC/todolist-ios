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

    func testParsesPlainTextFromStoredMarkdown() {
        let attributed = AttributedString(storedMarkdown: "Leite")
        XCTAssertEqual(String(attributed.characters), "Leite")
    }

    func testParsesBoldMarkdownIntoReadableCharacters() {
        let attributed = AttributedString(storedMarkdown: "**Leite**")
        XCTAssertEqual(String(attributed.characters), "Leite")
    }

    func testSerializesPlainTextUnchanged() {
        let context = Font.Context()
        var attributed = AttributedString("Leite")
        XCTAssertEqual(attributed.storedMarkdown(in: context), "Leite")
    }

    func testSerializesBoldRunBackToMarkdown() {
        let context = Font.Context()
        var attributed = AttributedString("Leite")
        attributed.font = Font.default.bold(true)
        XCTAssertEqual(attributed.storedMarkdown(in: context), "**Leite**")
    }
}
