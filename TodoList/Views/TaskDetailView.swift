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

    @Environment(\.appTheme) private var theme
    @State private var title: String
    @State private var newItemText = ""
    @State private var editingItemID: Int?
    @State private var editingText = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case newItem
        case editingItem
    }

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
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.text)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .onSubmit {
                    Task { await taskViewModel.renameList(currentList, title: title) }
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(currentList.items) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                Task { await taskViewModel.toggleCompleted(item, in: currentList) }
                            } label: {
                                Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(item.completed ? currentList.accentColor : theme.textSecondary)
                            }

                            if editingItemID == item.id {
                                TextField("Item", text: $editingText)
                                    .font(.system(size: 14))
                                    .foregroundStyle(theme.text)
                                    .focused($focusedField, equals: .editingItem)
                                    .submitLabel(.done)
                                    .onSubmit { saveEditingItem() }
                            } else {
                                Text.markdown(item.text)
                                    .font(.system(size: 14))
                                    .foregroundStyle(item.completed ? theme.textSecondary : theme.text)
                                    .strikethrough(item.completed)
                                    .onTapGesture {
                                        editingItemID = item.id
                                        editingText = item.text
                                        focusedField = .editingItem
                                    }
                            }

                            Spacer()

                            Button {
                                Task { await taskViewModel.deleteItem(item, from: currentList) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(18)
            }

            HStack(spacing: 10) {
                TextField("Novo item", text: $newItemText)
                    .foregroundStyle(theme.text)
                    .padding(10)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .focused($focusedField, equals: .newItem)
                    .submitLabel(.done)
                    .onSubmit(addItem)

                Button(action: addItem) {
                    Image(systemName: "plus")
                        .foregroundStyle(theme.background)
                        .frame(width: 36, height: 36)
                        .background(theme.text)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    applyFormatting(marker: "**")
                } label: {
                    Image(systemName: "bold")
                }
                Button {
                    applyFormatting(marker: "*")
                } label: {
                    Image(systemName: "italic")
                }
                Spacer()
                Button("OK") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: focusedField) { _, newValue in
            if newValue != .editingItem, editingItemID != nil {
                saveEditingItem()
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

    private func saveEditingItem() {
        guard let id = editingItemID, let item = currentList.items.first(where: { $0.id == id }) else { return }
        editingItemID = nil
        Task { await taskViewModel.updateItem(item, in: currentList, text: editingText, completed: item.completed) }
    }

    private func applyFormatting(marker: String) {
        switch focusedField {
        case .newItem:
            newItemText = MarkdownFormatting.toggling(newItemText, marker: marker)
        case .editingItem:
            editingText = MarkdownFormatting.toggling(editingText, marker: marker)
        case nil:
            break
        }
    }
}
