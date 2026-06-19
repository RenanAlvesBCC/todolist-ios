//
//  TaskList+Accent.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

extension TaskList {
    var accentColor: Color {
        Color.appAccents[id % Color.appAccents.count]
    }
}
