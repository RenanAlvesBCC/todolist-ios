//
//  RichTextField.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import SwiftUI

struct RichTextField: View {
    @Binding var text: AttributedString
    @Binding var selection: AttributedTextSelection
    @Binding var isFocused: Bool

    @Environment(\.appTheme) private var theme
    @FocusState private var focused: Bool

    var body: some View {
        TextEditor(text: $text, selection: $selection)
            .font(.system(size: 14))
            .foregroundStyle(theme.text)
            .scrollContentBackground(.hidden)
            .focused($focused)
            .onChange(of: focused) { _, newValue in
                isFocused = newValue
            }
            .onChange(of: isFocused) { _, newValue in
                focused = newValue
            }
    }
}
