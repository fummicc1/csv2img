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
        Group {
            if let cgImage = model.state.cgImage, model.state.exportType == .png {
                if let image = UIImage(cgImage: cgImage) {
                    ScrollView {
                        ScrollView(.horizontal, content: {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    width: calcSizeForImage(cgImage).width,
                                    height: calcSizeForImage(cgImage).height
                                )
                        })
                    }
                }
            } else if let document = model.state.pdfDocument, model.state.exportType == .pdf {
                PdfDocumentView(document: document, size: _size)
            }
        }
    }
    #elseif os(macOS)
    var body: some View {
        Group {
            if let cgImage = model.state.cgImage, model.state.exportType == .png {
                if let image = NSImage(
                    cgImage: cgImage,
                    size: CGSize(width: cgImage.width, height: cgImage.height)
                ) {
                    ScrollView(content: {
                        ScrollView(.horizontal, content: {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    width: calcSizeForImage(cgImage).width,
                                    height: calcSizeForImage(cgImage).height
                                )
                        })
                    })
                }
            } else if let document = model.state.pdfDocument, model.state.exportType == .pdf {
                PdfDocumentView(document: document, size: _size)
            }
        }
    }
    #endif

    private func calcSizeForImage(_ cgImage: CGImage) -> CGSize {
        let height = min(Int(size.height) * 2, cgImage.height)
        let width = min(Int(size.width) * 2, cgImage.width)
        return CGSize(width: width, height: height)
    }
}
