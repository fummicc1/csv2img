//
//  CsvBuilder.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import Foundation
import Csv2Img

public enum CsvBuilderError: Error {
}

public enum CsvBuilder {

    static let columnType: String = #"^CsvColumn\(wrappedValue: \".?\"\)$"#
    static let rowType: String = #"^CsvRow\(wrappedValue:.+, column: \".?\"\)$"#

    public static func inject<Composition: CsvComposition>(composition: Composition) throws -> Composition {
        let mirror = Mirror(reflecting: composition)
        let children = mirror.children
        for child in children {
            let value = String(describing: child.value)
            guard let _ = child.label else {
                continue
            }
            let columnExp = try NSRegularExpression(pattern: columnType)
            let columnMatches = columnExp.matches(
                in: value,
                range: NSRange(location: 0, length: value.count)
            )

            if !columnMatches.isEmpty {
                print(columnMatches)
            }

            let rowExp = try NSRegularExpression(pattern: rowType)
            let rowMatches = rowExp.matches(
                in: value,
                range: NSRange(location: 0, length: value.count)
            )
            if !rowMatches.isEmpty {
                print(rowMatches)
            }
        }
        fatalError()
    }

    public static func build() throws -> Csv {
        fatalError()
    }
}

public protocol CsvComposition {
}
