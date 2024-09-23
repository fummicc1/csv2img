//
//  GeneratePreviewView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/14.
//

import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct GeneratePreviewView: View {

    @StateObject var model: GenerateOutputModel
    @Binding var size: CGSize

    #if os(iOS)
        var body: some View {
            GeometryReader { geometry in
                Group {
                    if let cgImage = model.state.cgImage, model.state.exportType == .png {
                        let image = UIImage(cgImage: cgImage)
                        ScrollView([.vertical, .horizontal], showsIndicators: true) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    } else if let document = model.state.pdfDocument, model.state.exportType == .pdf {
                        PdfDocumentView(document: document, size: $size)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    #elseif os(macOS)
        var body: some View {
            GeometryReader { geometry in
                Group {
                    if let cgImage = model.state.cgImage, model.state.exportType == .png {
                        let image = NSImage(
                            cgImage: cgImage,
                            size: CGSize(width: cgImage.width, height: cgImage.height)
                        )
                        ScrollView([.vertical, .horizontal], showsIndicators: true) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    } else if let document = model.state.pdfDocument, model.state.exportType == .pdf {
                        PdfDocumentView(document: document, size: $size)
                    }
                }
            }
        }
    #endif
}

extension String.Encoding: Identifiable {
    public var id: UInt {
        self.rawValue
    }
}
