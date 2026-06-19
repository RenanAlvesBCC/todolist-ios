//
//  MarkdownFormatting.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

enum MarkdownFormatting {
    static func toggling(_ text: String, marker: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(marker), trimmed.hasSuffix(marker), trimmed.count >= marker.count * 2 {
            return String(trimmed.dropFirst(marker.count).dropLast(marker.count))
        }
        return marker + trimmed + marker
    }
}
