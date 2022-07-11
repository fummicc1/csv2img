//
//  ContentMode.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/07/11.
//

import Foundation


enum ContentMode: Equatable {
    case create
    case history(CsvOutput)
}
