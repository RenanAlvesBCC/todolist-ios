//
//  TaskGridView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct TaskGridView: View {
    let authViewModel: AuthViewModel
    let taskViewModel: TaskViewModel

    @Environment(\.appTheme) private var theme
    @State private var isShowingAddList = false
    @State private var isShowingSettings = false
    @State private var newListTitle = ""
    @State private var selectedList: TaskList?
    @State private var draggingListID: Int?

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let errorMessage = taskViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if taskViewModel.isLoading && taskViewModel.taskLists.isEmpty {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if taskViewModel.taskLists.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: taskViewModel.searchText.isEmpty ? "checklist" : "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundStyle(theme.textSecondary)
                        Text(taskViewModel.searchText.isEmpty ? "Nenhuma lista ainda" : "Nenhuma lista encontrada")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(taskViewModel.taskLists) { list in
                                TaskListCard(list: list) {
                                    selectedList = list
                                } onDelete: {
                                    Task { await taskViewModel.deleteList(list) }
                                }
                                .onDrag {
                                    draggingListID = list.id
                                    return NSItemProvider(object: String(list.id) as NSString)
                                }
                                .onDrop(of: [.text], delegate: TaskListDropDelegate(item: list, draggingListID: $draggingListID, taskViewModel: taskViewModel))
                            }
                        }
                        .padding(16)
                    }
                }

                Button {
                    isShowingAddList = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(theme.background)
                        .frame(width: 44, height: 44)
                        .background(theme.text)
                        .clipShape(Circle())
                }
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle("To-do list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(authViewModel: authViewModel)
            }
            .alert("Nova lista", isPresented: $isShowingAddList) {
                TextField("Título", text: $newListTitle)
                Button("Cancelar", role: .cancel) { newListTitle = "" }
                Button("Criar") {
                    Task {
                        await taskViewModel.addList(title: newListTitle)
                        newListTitle = ""
                    }
                }
            }
            .task {
                await taskViewModel.loadLists()
            }
            .navigationDestination(item: $selectedList) { list in
                TaskDetailView(taskViewModel: taskViewModel, list: list)
            }
            .searchable(text: Binding(
                get: { taskViewModel.searchText },
                set: { taskViewModel.searchText = $0 }
            ), prompt: "Buscar listas")
        }
    }
}
