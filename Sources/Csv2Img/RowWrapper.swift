//
//  CsvRows.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation


@propertyWrapper
public struct CsvRows {
    public var wrappedValue: [String]
    public var column: String

    public init(column: String) {
        self.column = column
        self.wrappedValue = []
    }
}
