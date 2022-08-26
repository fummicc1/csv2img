//
//  CsvRow.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/26.
//

import Foundation


extension Csv {
    /// Row (a line)
    ///
    /// Row is hrizontally separated group except first line.
    ///
    /// First line is treated as ``ColumnName``.
    ///
    /// eg.
    ///
    /// 1 2 3 4
    ///
    /// 5 6 7 8
    ///
    /// →Row is [5, 6, 7, 8].
    ///
    ///
    /// Because this class is usually initialized via ``Csv``, you do not have to take care about ``Row`` in detail.
    ///
    public struct Row {

        public init(index: Int, values: [String]) {
            self.index = index
            self.values = values
        }

        public var index: Int
        public var values: [String]

    }
}
