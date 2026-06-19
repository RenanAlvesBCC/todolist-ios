//
//  TaskDetailView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct TaskDetailView: View {
    let taskViewModel: TaskViewModel
    let list: TaskList

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var newItemText = ""

    init(taskViewModel: TaskViewModel, list: TaskList) {
        self.taskViewModel = taskViewModel
        self.list = list
        _title = State(initialValue: list.title)
    }

    private var currentList: TaskList {
        taskViewModel.taskLists.first(where: { $0.id == list.id }) ?? list
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Título", text: $title)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .onSubmit {
                    Task { await taskViewModel.renameList(currentList, title: title) }
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(currentList.items) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                Task { await taskViewModel.toggleCompleted(item, in: currentList) }
                            } label: {
                                Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(item.completed ? currentList.accentColor : Color.appTextSecondary)
                            }
                            Text(item.text)
                                .font(.system(size: 14))
                                .foregroundStyle(item.completed ? Color.appTextSecondary : Color.appText)
                                .strikethrough(item.completed)
                            Spacer()
                            Button {
                                Task { await taskViewModel.deleteItem(item, from: currentList) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }
                    }
                }
                .padding(18)
            }

            HStack(spacing: 10) {
                TextField("Novo item", text: $newItemText)
                    .padding(10)
                    .background(Color.appCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit(addItem)

                Button(action: addItem) {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.appText)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .onDisappear {
            if title != currentList.title {
                Task { await taskViewModel.renameList(currentList, title: title) }
            }
        }
    }

    private func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = newItemText
        newItemText = ""
        Task { await taskViewModel.addItem(text: text, to: currentList) }
    }
}
