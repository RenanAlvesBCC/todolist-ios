//
//  TaskListDropDelegate.swift
//  TodoList
//
//  Created by Renan Alves on 21/06/26.
//

import SwiftUI

struct TaskListDropDelegate: DropDelegate {
    let item: TaskList
    @Binding var draggingListID: Int?
    let taskViewModel: TaskViewModel

    func dropEntered(info: DropInfo) {
        guard let draggingListID, draggingListID != item.id else { return }
        taskViewModel.moveLists(fromID: draggingListID, toID: item.id)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingListID = nil
        Task { await taskViewModel.persistListOrder() }
        return true
    }
}
