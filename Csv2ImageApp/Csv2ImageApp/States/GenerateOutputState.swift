//
//  GenerateOutputState.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import Csv2Img


struct GenerateOutputState: Hashable {
    let url: URL
    let fileType: FileURLType

    var data: AnyCsvExportable?
    var exportMode: Csv.ExportType

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(fileType)
        hasher.combine(exportMode)
    }

    static func ==(lhs: GenerateOutputState, rhs: GenerateOutputState) -> Bool {
        lhs.url == rhs.url && lhs.exportMode == rhs.exportMode && lhs.fileType == rhs.fileType
    }
}
