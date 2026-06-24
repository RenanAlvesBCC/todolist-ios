//
//  MockCacheService.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

@testable import TodoList

final class MockCacheService: CacheServiceProtocol {
    var savedLists: [TaskList] = []
    var deletedListIDs: [Int] = []
    var upsertedItems: [TaskItem] = []
    var deletedItemIDs: [Int] = []
    private(set) var replacedTempIDs: [(temp: Int, real: TaskList)] = []
    private(set) var replacedTempItemIDs: [(temp: Int, real: TaskItem)] = []

    func saveLists(_ lists: [TaskList]) { savedLists = lists }
    func loadLists(userID: Int) -> [TaskList] { savedLists }
    func upsertList(_ list: TaskList) {
        if let index = savedLists.firstIndex(where: { $0.id == list.id }) {
            savedLists[index] = list
        } else {
            savedLists.append(list)
        }
    }
    func deleteList(serverID: Int) { savedLists.removeAll { $0.id == serverID } }
    func upsertItem(_ item: TaskItem) { upsertedItems.append(item) }
    func deleteItem(serverID: Int) { deletedItemIDs.append(serverID) }
    func replaceTempID(_ tempID: Int, with realList: TaskList) {
        replacedTempIDs.append((tempID, realList))
        if let index = savedLists.firstIndex(where: { $0.id == tempID }) {
            savedLists[index] = realList
        }
    }
    func replaceTempItemID(_ tempID: Int, with realItem: TaskItem) {
        replacedTempItemIDs.append((tempID, realItem))
    }
}
