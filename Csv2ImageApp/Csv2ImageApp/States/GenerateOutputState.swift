//
//  GenerateOutputState.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import PDFKit
import Csv2Img


struct GenerateOutputState: Hashable {
    let url: URL
    let fileType: FileURLType

    var cgImage: CGImage?
    var pdfDocument: PDFDocument?
    var exportType: Csv.ExportType

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(fileType)
        hasher.combine(exportType)
        if let cgImage = cgImage {
            hasher.combine(cgImage.convertToData())
        }
        if let pdfDocument = pdfDocument {
            hasher.combine(pdfDocument.dataRepresentation())
        }
    }

    static func ==(lhs: GenerateOutputState, rhs: GenerateOutputState) -> Bool {
        lhs.url == rhs.url && lhs.exportType == rhs.exportType && lhs.fileType == rhs.fileType && lhs.cgImage?.convertToData() == rhs.cgImage?.convertToData() && lhs.pdfDocument?.dataRepresentation() == rhs.pdfDocument?.dataRepresentation()
    }
}
