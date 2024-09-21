//
//  GenerateOutputView+macOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Csv2Img
import PDFKit
import SwiftUI

#if os(macOS)
    struct GenerateOutputView_macOS: View {

        @StateObject var model: GenerateOutputModel
        @Binding var backToPreviousPage: Bool

        private let availableEncodingType: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf32,
            .shiftJIS,
            .ascii,
        ]

        @Environment(\.dismiss) var dismiss

        var body: some View {
            VStack {
                GeneratePreviewView(
                    model: model,
                    size: .constant(
                        .init(
                            width: 320,
                            height: 240
                        )
                    )
                )
            }
            .toolbar {
                CButton.labeled(
                    "cancel",
                    onPressed: {
                        dismiss()
                    }
                )
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
