//
//  SwiftUI+PdfDocument.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/22.
//

import SwiftUI
import PDFKit


struct PdfDocumentView: ViewRepresentable {

    let document: PDFDocument
    @Binding var size: CGSize

    private let view: PDFView = .init()

    #if os(macOS)
    typealias NSViewType = PDFView
    func makeNSView(context: Context) -> PDFView {
        view.document = document
        view.setFrameSize(size)
        view.autoScales = true
        return view
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
    }
    #elseif os(iOS)
    typealias UIViewType = PDFView

    func makeUIView(context: Context) -> PDFView {
        view.document = document
        view.frame.size = size
        view.autoScales = true
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
    }
    #endif
}

struct PdfDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        PdfDocumentView(document: .init(), size: .constant(CGSize(width: 100, height: 100)))
    }
}
