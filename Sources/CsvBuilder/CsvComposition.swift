//
//  CsvComposition.swift
//
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import Csv2Img
import Foundation

public protocol CsvComposition {
    func build() throws -> Csv
}

extension CsvComposition {
    public func build() throws -> Csv {
        try CsvBuilder.build(
            composition: self
        )
    }
}
