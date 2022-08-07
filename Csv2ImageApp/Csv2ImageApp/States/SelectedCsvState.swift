//
//  SelectedCsvState.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation


enum FileURLType {
    case local
    case network
}

struct SelectedCsvState: Hashable {
    let fileType: FileURLType
    let url: URL
}
