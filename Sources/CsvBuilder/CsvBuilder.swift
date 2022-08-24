//
//  CsvBuilder.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import Foundation
import Csv2Img
import SwiftSyntaxParser

public enum CsvBuilderError: Error {
}

public protocol CsvBuilder {
    func build() throws -> Csv
}

public protocol CsvComposition {
}

extension CsvBuilder {
    public func build() throws -> Csv {
        fatalError()
    }
}
