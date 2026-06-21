//
//  TaskDetailView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//
import SwiftUI
import UniformTypeIdentifiers

struct TaskDetailView: View {
    let taskViewModel: TaskViewModel
    let list: TaskList

    @Environment(\.appTheme) private var theme
    @Environment(\.fontResolutionContext) private var fontResolutionContext
    @State private var title: String
    @State private var newItemText = AttributedString()
    @State private var newItemSelection = AttributedTextSelection()
    @State private var editingItemID: Int?
    @State private var editingText = AttributedString()
    @State private var editingSelection = AttributedTextSelection()
    @State private var draggingItemID: Int?
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case newItem
        case editingItem
    }

    private enum FormattingTrait {
        case bold, italic
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
                                RichTextField(
                                    text: $editingText,
                                    selection: $editingSelection,
                                    isFocused: Binding(
                                        get: { focusedField == .editingItem },
                                        set: { newValue in
                                            if newValue {
                                                focusedField = .editingItem
                                            } else if focusedField == .editingItem {
                                                focusedField = nil
                                            }
                                        }
                                    )
                                )
                                .frame(minHeight: 30)
                            } else {
                                Text.markdown(item.text)
                                    .font(.system(size: 14))
                                    .foregroundStyle(item.completed ? theme.textSecondary : theme.text)
                                    .strikethrough(item.completed)
                                    .onTapGesture {
                                        editingItemID = item.id
                                        editingText = AttributedString(storedMarkdown: item.text)
                                        editingSelection = AttributedTextSelection()
                                        focusedField = .editingItem
                                    }
                            }

                            Spacer()

                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 12))
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .onDrag {
                                    draggingItemID = item.id
                                    return NSItemProvider(object: String(item.id) as NSString)
                                }

                            Button {
                                Task { await taskViewModel.deleteItem(item, from: currentList) }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        .onDrop(of: [.text], delegate: TaskItemDropDelegate(item: item, list: currentList, draggingItemID: $draggingItemID, taskViewModel: taskViewModel))
                    }
                }
                .padding(18)
            }

            HStack(alignment: .top, spacing: 10) {
                RichTextField(
                    text: $newItemText,
                    selection: $newItemSelection,
                    isFocused: Binding(
                        get: { focusedField == .newItem },
                        set: { newValue in
                            if newValue {
                                focusedField = .newItem
                            } else if focusedField == .newItem {
                                focusedField = nil
                            }
                        }
                    )
                )
                .frame(minHeight: 36, maxHeight: 80)
                .padding(6)
                .background(theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))

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
                    applyFormatting(.bold)
                } label: {
                    Image(systemName: "bold")
                }
                Button {
                    applyFormatting(.italic)
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
        let text = newItemText.storedMarkdown(in: fontResolutionContext)
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        newItemText = AttributedString()
        newItemSelection = AttributedTextSelection()
        Task { await taskViewModel.addItem(text: text, to: currentList) }
    }

    private func saveEditingItem() {
        guard let id = editingItemID, let item = currentList.items.first(where: { $0.id == id }) else { return }
        editingItemID = nil
        let text = editingText.storedMarkdown(in: fontResolutionContext)
        Task { await taskViewModel.updateItem(item, in: currentList, text: text, completed: item.completed) }
    }

    private func applyFormatting(_ trait: FormattingTrait) {
        switch focusedField {
        case .newItem:
            apply(trait, to: &newItemText, selection: &newItemSelection)
        case .editingItem:
            apply(trait, to: &editingText, selection: &editingSelection)
        case nil:
            break
        }
    }

    private func apply(_ trait: FormattingTrait, to text: inout AttributedString, selection: inout AttributedTextSelection) {
        text.transformAttributes(in: &selection) { container in
            let currentFont = container.font ?? .default
            let resolved = currentFont.resolve(in: fontResolutionContext)
            switch trait {
            case .bold:
                container.font = currentFont.bold(!resolved.isBold)
            case .italic:
                container.font = currentFont.italic(!resolved.isItalic)
            }
        }
    }
}
