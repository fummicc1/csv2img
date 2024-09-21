//
//  File.swift
//
//
//  Created by Fumiya Tanaka on 2023/02/01.
//

import Foundation

/// Under development
public struct NewCsvComposition<
    Row,
    Column: StringProtocol
> {
    var columns: [Column]
    var rows: Rows

    @dynamicMemberLookup
    public struct Rows {
        public typealias Value = [Column: [Row]]
        var value: Value = [:]

        subscript(
            dynamicMember keyPath: KeyPath<
                Rows,
                [Rows]
            >
        ) -> Value {
            fatalError()
        }
    }
}
