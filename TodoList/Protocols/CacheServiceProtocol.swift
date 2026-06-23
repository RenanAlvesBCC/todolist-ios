//
//  CacheServiceProtocol.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

protocol CacheServiceProtocol {
    func saveLists(_ lists: [TaskList])
    func loadLists(userID: Int) -> [TaskList]
    func upsertList(_ list: TaskList)
    func deleteList(serverID: Int)
    func upsertItem(_ item: TaskItem)
    func deleteItem(serverID: Int)
    func replaceTempID(_ tempID: Int, with realList: TaskList)
    func replaceTempItemID(_ tempID: Int, with realItem: TaskItem)
}
