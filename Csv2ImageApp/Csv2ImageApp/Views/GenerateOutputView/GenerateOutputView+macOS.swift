//
//  GenerateOutputView+macOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI
import Csv2Img
import PDFKit

#if os(macOS)
struct GenerateOutputView_macOS: View {

    @StateObject var model: GenerateOutputModel
    @Binding var backToPreviousPage: Bool

    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { proxy in
            VStack {
                HStack {
                    CButton.labeled("Back") {
                        withAnimation {
                            backToPreviousPage = true
                        }
                    }
                    Spacer()
                }
                .padding()
                Group {
                    if let cgImage = model.state.cgImage, model.state.exportType == .png {
                        if let image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height)) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    width: proxy.size.width * 0.7,
                                    height: proxy.size.height * 0.7
                                )
                        }
                    } else if let document = model.state.pdfDocument, model.state.exportType == .pdf {
                        PdfDocumentView(document: document)
                    }
                }
                Spacer()
                HStack {
                    Picker(selection: $model.state.exportType) {
                        CText("png").tag(Csv.ExportType.png)
                        CText("pdf").tag(Csv.ExportType.pdf)
                    } label: {
                        CText("Export Type")
                    }
                    .padding()
                    .pickerStyle(.radioGroup)
                    .background(Asset.backgroundColor.swiftUIColor)
                    .padding()

                    Spacer()
                    CButton.labeled("Save", role: .primary) {
                        model.save()
                    }
                }.padding()
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
