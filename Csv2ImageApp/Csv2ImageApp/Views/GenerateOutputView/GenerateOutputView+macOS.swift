//
//  GenerateOutputView+macOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI
import PDFKit

#if os(macOS)
struct GenerateOutputView_macOS: View {

    @ObservedObject var model: GenerateOutputModel
    @Binding var backToPreviousPage: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Group {
                switch model.state.exportMode {
                case .png:
                    if let imageData = model.state.data?.base as? Data, let image = NSImage(data: imageData) {
                        Image(nsImage: image)
                    }
                case .pdf:
                    if let document = model.state.data?.base as? PDFDocument {
                        PdfDocumentView(document: document)
                    } else {

                    }
                }
            }

            CButton.labeled("Back") {
                withAnimation {
                    backToPreviousPage = true
                }
            }
        }
    }
}

struct GenerateOutputView_macOS_Previews: PreviewProvider {
    static var previews: some View {
        GenerateOutputView_macOS(
            model: GenerateOutputModel(
                url: URL(string: "https://via.placeholder.com/150")!,
                urlType: .network
            ),
            backToPreviousPage: .constant(false)
        )
    }
}
#endif
