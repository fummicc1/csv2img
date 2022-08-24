//
//  CsvRow.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation


@propertyWrapper
public struct CsvRow {
    public var wrappedValue: [String]
    public var column: String

    public init(column: String) {
        self.column = column
        self.wrappedValue = []
    }
}
