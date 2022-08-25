//
//  ColumnWrapper.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation


@propertyWrapper
public struct CsvColumn {
    public var wrappedValue: String

    public init(_ wrappedValue: String? = nil) {
        if let wrappedValue = wrappedValue {
            self.wrappedValue = wrappedValue
        } else {
            self.wrappedValue = ""
        }
    }
}
