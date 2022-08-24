//
//  Example.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation
import Csv2Img


public struct Example: CsvComposition {
    @CsvColumn
    var name: String

    @CsvColumn
    var age: String

    @CsvRow(column: "age")
    var ages: [String]

    @CsvRow(column: "name")
    var names: [String]
}


public struct ExampleBuilder: CsvBuilder {

    var raw: String = """
name,age
tanaka, 100
sato, 99
yamada, 98
"""

    public func build() async throws -> Csv {
        return await Csv().loadFromString(raw)
    }
}
