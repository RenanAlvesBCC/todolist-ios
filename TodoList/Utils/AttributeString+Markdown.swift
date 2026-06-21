//
//  AttributeString+Markdown.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import SwiftUI

extension AttributedString {
    init(storedMarkdown text: String) {
        self = (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }

    func storedMarkdown(in context: Font.Context) -> String {
        var result = ""
        for run in runs {
            let substring = String(characters[run.range])
            let resolvedFont = (run.font ?? .default).resolve(in: context)

            var wrapped = substring
            if resolvedFont.isItalic {
                wrapped = "*" + wrapped + "*"
            }
            if resolvedFont.isBold {
                wrapped = "**" + wrapped + "**"
            }
            result += wrapped
        }
        return result
    }
}
