//
//  Text+Markdown.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

extension Text {
    static func markdown(_ string: String) -> Text {
        Text((try? AttributedString(markdown: string)) ?? AttributedString(string))
    }
}
