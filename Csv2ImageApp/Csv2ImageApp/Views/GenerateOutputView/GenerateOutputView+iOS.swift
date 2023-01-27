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
    @State private var succeedSavingOutput: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .background(Asset.lightAccentColor.swiftUIColor)
                .ignoresSafeArea()
            Group {
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
                    Picker(selection: Binding(get: {
                        model.state.exportType
                    }, set: { exportType in
                        model.update(keyPath: \.exportType, value: exportType)
                    })) {
                        CText("PDF")
                            .tag(Csv.ExportType.pdf)
                        CText("PNG")
                            .tag(Csv.ExportType.png)
                    } label: {
                        CText("Export Type")
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    GeometryReader { proxy in
                        VStack {
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
                            HStack {
                                Spacer()
                                CButton.labeled("Save") {
                                    succeedSavingOutput = model.save()
                                }
                            }
                            .padding()
                        }
                    }
                }
                .background(Asset.lightAccentColor.swiftUIColor)
            }
            if model.state.isLoading {
                ProgressView {
                    CText("Loading...", font: .largeTitle)
                }
                .padding()
                .progressViewStyle(.linear)
            }
        }
        .background(Asset.lightAccentColor.swiftUIColor)
        .alert("Complete Saving!", isPresented: $succeedSavingOutput) {
            CButton.labeled("Back") {
                withAnimation {
                    backToPreviousPage = true
                }
            }
            if let savedURL = model.savedURL, Application.shared.canOpenURL(savedURL) {
                CButton.labeled("Open") {
                    Application.shared.open(savedURL)
                }
            }
        }
    }
}
#endif
