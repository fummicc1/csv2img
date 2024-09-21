//
//  GenerateOutputView+iOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Csv2Img
import SwiftUI

#if os(iOS)
    struct GenerateOutputView_iOS: View {

        @StateObject var model: GenerateOutputModel
        @Binding var backToPreviousPage: Bool
        @State private var succeedSavingOutput: Bool = false

        private let availableEncodingType: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf32,
            .shiftJIS,
            .ascii,
        ]

        var body: some View {
            NavigationStack {
                loadedContent.id(model.state.isLoading)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Save") {
                                succeedSavingOutput = model.save()
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Back") {
                                backToPreviousPage = true
                            }
                        }
                    }
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

        var loadedContent: some View {
            VStack {
                List {
                    Section("Export Type") {
                        Picker(
                            selection: Binding(
                                get: {
                                    model.state.exportType
                                },
                                set: { exportType in
                                    model.update(keyPath: \.exportType, value: exportType)
                                })
                        ) {
                            CText("PDF")
                                .tag(Csv.ExportType.pdf)
                            CText("PNG")
                                .tag(Csv.ExportType.png)
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Encoding") {
                        Menu(model.state.encoding.description) {
                            ForEach(availableEncodingType, id: \.self) { encoding in
                                Button {
                                    model.update(keyPath: \.encoding, value: encoding)
                                } label: {
                                    Text(encoding.description)
                                }
                            }
                        }
                        .fixedSize()
                    }
                    Section("PDF Size") {
                        Menu(model.state.size.rawValue) {
                            ForEach(PdfSize.allCases.indices, id: \.self) { index in
                                let size = PdfSize.allCases[index]
                                Button {
                                    model.update(keyPath: \.size, value: size)
                                } label: {
                                    Text(size.rawValue)
                                }
                            }
                        }
                        .fixedSize()
                    }
                    Section("PDF Orientation") {
                        Menu(model.state.orientation.rawValue) {
                            ForEach(PdfSize.Orientation.allCases.indices, id: \.self) { index in
                                let orientation = PdfSize.Orientation.allCases[index]
                                Button {
                                    model.update(keyPath: \.orientation, value: orientation)
                                } label: {
                                    Text(orientation.rawValue)
                                }
                            }
                        }
                        .fixedSize()
                    }
                }
                .background(Asset.lightAccentColor.swiftUIColor)
                .frame(maxHeight: 200)

                GeometryReader { proxy in
                    VStack(alignment: .center) {
                        GeneratePreviewView(
                            model: model,
                            size: .constant(
                                CGSize(
                                    width: proxy.size.width,
                                    height: proxy.size.height
                                )
                            )
                        )
                    }

                }
                .background(Asset.lightAccentColor.swiftUIColor)
            }
        }

        var loadingContent: some View {
            ProgressView {
                CText("Loading...", font: .largeTitle)
            }
            .padding()
            .progressViewStyle(.linear)
        }
    }
#endif
