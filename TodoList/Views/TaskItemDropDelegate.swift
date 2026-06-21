//
//  TaskItemDropDelegate.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import SwiftUI

struct TaskItemDropDelegate: DropDelegate {
    let item: TaskItem
    let list: TaskList
    @Binding var draggingItemID: Int?
    let taskViewModel: TaskViewModel

    func dropEntered(info: DropInfo) {
        guard let draggingItemID, draggingItemID != item.id else { return }
        taskViewModel.moveItems(in: list, fromID: draggingItemID, toID: item.id)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingItemID = nil
        Task { await taskViewModel.persistItemOrder(for: list) }
        return true
    }
}
