//
//  SwiftUI+PdfDocument.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/22.
//

import SwiftUI
import PDFKit


struct PdfDocumentView: ViewRepresentable {
    typealias NSViewType = PDFView


    let document: PDFDocument

    private let view: PDFView = .init()

    #if os(macOS)
    func makeNSView(context: Context) -> PDFView {
        view.document = document
        view.setFrameSize(view.fittingSize)
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
    }
    #elseif os(iOS)
    #endif
}

struct PdfDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        PdfDocumentView(document: .init())
    }
}
