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

    static let rowRegex: String = #"^CsvRows\(wrappedValue: (\[.*\]), column: \"(.+)\"\)$"#

    public static func build(composition: CsvComposition) throws -> Csv {
        let mirror = Mirror(reflecting: composition)
        let children = mirror.children

        var elements: [CsvCompositionElement] = []
        var rowSize: Int = 0

        for child in children {
            let value = String(describing: child.value)
            guard let _ = child.label else {
                continue
            }

            let rowExp = try NSRegularExpression(pattern: rowRegex)
            let rowMatches = rowExp.matches(
                in: value,
                range: NSRange(location: 0, length: value.count)
            )
            if !rowMatches.isEmpty {
                if let result = rowMatches.last {
                    if let rowRange = Range(result.range(at: 1), in: value), let columnRange = Range(result.range(at: 2), in: value) {
                        let columnName = String(value[columnRange])
                        let rows = trim(str: String(value[rowRange]))
                        let column = CsvCompositionElement(
                            column: columnName,
                            rows: rows
                        )
                        rowSize = max(rowSize, rows.count)
                        elements.append(column)
                    }
                }
            }
        }
        if elements.isEmpty {
            throw Csv.Error.emptyData
        }
        let styles = Csv.Column.Style.random(count: elements.count)
        let columns: [Csv.Column] = elements
            .map(\.columnName)
            .enumerated()
            .map { Csv.Column(name: $0.element, style: styles[$0.offset]) }

        var rows: [Csv.Row] = []
        let flattedRows = elements.map(\.rows).flatMap { $0 }
        for i in 0..<rowSize {
            let values = flattedRows.filter { $0.index == i }
            let row = Csv.Row(index: i, values: values.map(\.value))
            rows.append(row)
        }

        return Csv(
            separator: ",",
            columns: columns,
            rows: rows,
            exportType: .pdf
        )
    }

    static func trim(str: String) -> [CsvCompositionElement.Row] {
        var str = str
        let head = "\""
        let tail = ","
        str = str
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        str = str.replacingOccurrences(of: head, with: "")
        str = str.replacingOccurrences(of: tail, with: "\n")
        let rows = str.split(separator: "\n")
            .enumerated()
            .map {
                CsvCompositionElement.Row(
                    index: $0.offset,
                    value: String($0.element.trimmingCharacters(in: .whitespaces))
                )
            }
        return rows
    }
}
