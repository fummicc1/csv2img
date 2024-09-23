//
//  SwiftUI+PdfDocument.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/22.
//

import PDFKit
import SwiftUI

struct PdfDocumentView: ViewRepresentable {

    @Binding var document: PDFDocument?
    let size: CGSize

    private let view: PDFView = .init()

    #if os(macOS)
        typealias NSViewType = PDFView
        func makeNSView(context: Context) -> PDFView {
            view.document = document
            view.setFrameSize(size)
            view.displayMode = .twoUpContinuous
            return view
        }

        func updateNSView(_ nsView: PDFView, context: Context) {
            nsView.document = document
            nsView.setFrameSize(size)
            nsView.displayMode = .twoUpContinuous
        }
    #elseif os(iOS)
        typealias UIViewType = PDFView

        func makeUIView(context: Context) -> PDFView {
            view.document = document
            view.frame.size = size
            view.displayMode = .singlePage
            view.usePageViewController(true, withViewOptions: nil)
            return view
        }
        func updateUIView(_ uiView: PDFView, context: Context) {
            uiView.document = document
            uiView.frame.size = size
            uiView.displayMode = .singlePage
            uiView.usePageViewController(true, withViewOptions: nil)
        }
    #endif
}

struct PdfDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        PdfDocumentView(
            document: .constant(
                .init()
            ),
            size: CGSize(width: 100, height: 100)
        )
    }
}
