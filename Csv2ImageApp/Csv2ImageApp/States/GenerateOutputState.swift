//
//  GenerateOutputState.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Csv2Img
import Foundation
import PDFKit

struct GenerateOutputState: Hashable, Equatable {
    let url: URL
    let fileType: FileURLType

    var isLoading: Bool
    var progress: Double
    var errorMessage: String?

    var encoding: String.Encoding
    var exportType: Csv.ExportType
    var size: PdfSize = .a3
    var orientation: PdfSize.Orientation = .portrait

    var cgImage: CGImage?
    var pdfDocument: PDFDocument?

    init(
        url: URL,
        fileType: FileURLType,
        isLoading: Bool = false,
        progress: Double = 0,
        errorMessage: String? = nil,
        encoding: String.Encoding = .utf8,
        cgImage: CGImage? = nil,
        pdfDocument: PDFDocument? = nil,
        exportType: Csv.ExportType = .pdf
    ) {
        self.url = url
        self.fileType = fileType
        self.isLoading = isLoading
        self.progress = progress
        self.errorMessage = errorMessage
        self.encoding = encoding
        self.cgImage = cgImage
        self.pdfDocument = pdfDocument
        self.exportType = exportType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(fileType)
        hasher.combine(encoding.id)
        hasher.combine(exportType)
        if let cgImage = cgImage {
            hasher.combine(cgImage.convertToData())
        }
        if let pdfDocument = pdfDocument {
            hasher.combine(pdfDocument.dataRepresentation())
        }
    }

    static func == (lhs: GenerateOutputState, rhs: GenerateOutputState) -> Bool {
        lhs.url == rhs.url && lhs.exportType == rhs.exportType && lhs.fileType == rhs.fileType
            && lhs.encoding == rhs.encoding
            && lhs.cgImage?.convertToData() == rhs.cgImage?.convertToData()
            && lhs.pdfDocument?.dataRepresentation() == rhs.pdfDocument?.dataRepresentation()
    }
}

extension String.Encoding {
    //    static func ==(lhs: String.Encoding, rhs: String.Encoding) -> Bool {
    //        lhs.id == rhs.id
    //    }
}
