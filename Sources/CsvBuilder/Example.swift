//
//  Example.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation
import Csv2Img


public struct ExampleComposition: CsvComposition {
    @CsvColumn
    var name: String

    @CsvColumn
    var age: String

    @CsvRow(column: "age")
    var ages: [String]

    @CsvRow(column: "name")
    var names: [String]


}
