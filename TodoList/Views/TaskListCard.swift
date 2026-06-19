//
//  TaskListCard.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct TaskListCard: View {
    let list: TaskList
    let onTap: () -> Void
    let onDelete: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(list.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.text)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(list.items.prefix(4)) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                        Text.markdown(item.text)
                            .font(.system(size: 11))
                            .foregroundStyle(item.completed ? theme.textSecondary : theme.text)
                            .strikethrough(item.completed)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 18, height: 18)
                    .background(theme.textSecondary.opacity(0.18))
                    .clipShape(Circle())
            }
            .padding(6)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(list.accentColor)
                .frame(width: 3)
        }
        .onTapGesture(perform: onTap)
    }
}
