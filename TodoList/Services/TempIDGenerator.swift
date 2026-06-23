//
//  TempIDGenerator.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

final class TempIDGenerator {
    private var current = -1

    func next() -> Int {
        defer { current -= 1 }
        return current
    }
}
