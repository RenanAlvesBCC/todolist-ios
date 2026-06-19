//
//  ContentView.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
                    Text("To-do list")
                        .font(.title)
                        .fontWeight(.medium)
                    Text("Pronto pra conectar na API")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
    }
}

#Preview {
    ContentView()
}
