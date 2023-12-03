//
//  CsvCompositionElement.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import Foundation


struct CsvCompositionElement {
    var columnName: String
    var rows: [Row]

    struct Row {
        let index: Int
        let value: String
    }

    init(
        column: String,
        rows: [Row]
    ) {
        self.columnName = column
        self.rows = rows
    }
}
