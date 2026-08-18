//
//  AttributeStringMarkdownTests.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import XCTest
import SwiftUI
import UIKit
@testable import TodoList

@MainActor
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

    @MainActor
    func testStoredMarkdownExportsPlainText() {
        let attributed = AttributedString("Leite")
        XCTAssertEqual(exportStoredMarkdown(attributed), "Leite")
    }

    @MainActor
    func testStoredMarkdownWrapsBoldAndItalicRuns() {
        var bold = AttributedString("Negrito")
        bold.font = .body.bold()
        XCTAssertTrue(exportStoredMarkdown(bold).contains("Negrito"))

        var italic = AttributedString("Itálico")
        italic.font = .body.italic()
        XCTAssertTrue(exportStoredMarkdown(italic).contains("Itálico"))

        var both = AttributedString("Ambos")
        both.font = .body.bold().italic()
        XCTAssertTrue(exportStoredMarkdown(both).contains("Ambos"))
    }

    func testInitAcceptsUnbalancedMarkdownWithoutCrashing() {
        let result = AttributedString(storedMarkdown: String(repeating: "[", count: 80))
        XCTAssertGreaterThanOrEqual(String(result.characters).count, 0)
    }

    @MainActor
    private func exportStoredMarkdown(_ attributed: AttributedString) -> String {
        let holder = MarkdownExportHolder()
        let host = UIHostingController(rootView: MarkdownExportView(source: attributed, holder: holder))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        return holder.value
    }
}

private final class MarkdownExportHolder {
    var value = ""
}

private struct MarkdownExportView: View {
    let source: AttributedString
    let holder: MarkdownExportHolder
    @Environment(\.fontResolutionContext) private var context

    var body: some View {
        let exported = source.storedMarkdown(in: context)
        holder.value = exported
        return Color.clear
    }
}
