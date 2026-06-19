//
//  TaskGridView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

private struct TaskListCard: View {
    let list: TaskList
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(list.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appText)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(list.items.prefix(4)) { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.completed ? "checkmark.square.fill" : "square")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextSecondary)
                        Text(item.text)
                            .font(.system(size: 11))
                            .foregroundStyle(item.completed ? Color.appTextSecondary : Color.appText)
                            .strikethrough(item.completed)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .topTrailing) {
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 18, height: 18)
                    .background(Color.appTextSecondary.opacity(0.18))
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

struct TaskGridView: View {
    let authViewModel: AuthViewModel
    let taskViewModel: TaskViewModel

    @State private var isShowingAddList = false
    @State private var isShowingMenu = false
    @State private var newListTitle = ""
    @State private var selectedList: TaskList?

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
                        Image(systemName: "checklist")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Nenhuma lista ainda")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
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
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.appText)
                        .clipShape(Circle())
                }
                .padding(.bottom, 14)
            }
            .navigationTitle("To-do list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                }
            }
            .confirmationDialog("Menu", isPresented: $isShowingMenu, titleVisibility: .hidden) {
                Button("Sair", role: .destructive) {
                    authViewModel.logout()
                }
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
        }
    }
}
