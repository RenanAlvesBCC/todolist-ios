//
//  URLSessionProtocol.swift
//  TodoList
//
//  Created by Renan Alves on 19/06/26.
//

import Foundation

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}
