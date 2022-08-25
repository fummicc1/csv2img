//
//  CsvComposition.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import Foundation
import Csv2Img

public protocol CsvComposition {
    func build() throws -> Csv
}

extension CsvComposition {
    public func build() throws -> Csv {
        try CsvBuilder.build(composition: self)
    }
}
