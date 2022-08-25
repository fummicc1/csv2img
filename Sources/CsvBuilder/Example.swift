//
//  Example.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/24.
//

import Foundation
import Csv2Img


public struct ExampleComposition: CsvComposition {
    @CsvRows(column: "age")
    public var ages: [String]

    @CsvRows(column: "name")
    public var names: [String]

    public init() { }
}
