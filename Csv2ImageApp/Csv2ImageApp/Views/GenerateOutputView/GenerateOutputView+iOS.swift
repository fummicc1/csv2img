//
//  GenerateOutputView+iOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI
import Csv2Img


#if os(iOS)
struct GenerateOutputView_iOS: View {

    @StateObject var model: GenerateOutputModel
    @Binding var backToPreviousPage: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .background(Asset.lightAccentColor.swiftUIColor)
                .ignoresSafeArea()
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
                    Picker(selection: $model.state.exportType) {
                        CText("PDF")
                            .tag(Csv.ExportType.pdf)
                        CText("PNG")
                            .tag(Csv.ExportType.png)
                    } label: {
                        CText("Export Type")
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    GeneratePreviewView(
                        model: model,
                        size: .constant(
                            CGSize(
                                width: proxy.size.width * 0.85,
                                height: proxy.size.height * 0.8
                            )
                        )
                    )
                    .padding()
                    Spacer()
                }
                .background(Asset.lightAccentColor.swiftUIColor)
            }
        }.background(Asset.lightAccentColor.swiftUIColor)
    }
}
#endif
