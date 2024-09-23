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
            NavigationView {
                Form {
                    Section(header: Text("Export Settings")) {
                        Picker(
                            "Export Type",
                            selection: Binding(
                                get: { model.state.exportType },
                                set: { model.update(keyPath: \.exportType, value: $0) }
                            )
                        ) {
                            Text("PDF").tag(Csv.ExportType.pdf)
                            Text("PNG").tag(Csv.ExportType.png)
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Picker(
                            "Encoding",
                            selection: Binding(
                                get: { model.state.encoding },
                                set: { model.update(keyPath: \.encoding, value: $0) }
                            )
                        ) {
                            ForEach(availableEncodingType, id: \.self) { encoding in
                                Text(encoding.description).tag(encoding)
                            }
                        }

                        Picker(
                            "PDF Size",
                            selection: Binding(
                                get: { model.state.size },
                                set: { model.update(keyPath: \.size, value: $0) }
                            )
                        ) {
                            ForEach(PdfSize.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }

                        Picker(
                            "PDF Orientation",
                            selection: Binding(
                                get: { model.state.orientation },
                                set: { model.update(keyPath: \.orientation, value: $0) }
                            )
                        ) {
                            ForEach(PdfSize.Orientation.allCases, id: \.self) { orientation in
                                Text(orientation.rawValue).tag(orientation)
                            }
                        }
                    }

                    Section(header: Text("Preview")) {
                        GeneratePreviewView(
                            model: model,
                            size: .constant(
                                CGSize(width: UIScreen.main.bounds.width - 32, height: 300))
                        )
                        .frame(height: 300)
                        .background(Asset.lightAccentColor.swiftUIColor)
                        .cornerRadius(8)
                    }
                }
                .navigationBarTitle("Generate Output", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Back") { backToPreviousPage = true },
                    trailing: Button("Save") { succeedSavingOutput = model.save() }
                )
            }
            .alert(isPresented: $succeedSavingOutput) {
                Alert(
                    title: Text("Complete Saving!"),
                    message: nil,
                    primaryButton: .default(Text("Back")) {
                        withAnimation {
                            backToPreviousPage = true
                        }
                    },
                    secondaryButton: .default(Text("Open")) {
                        if let savedURL = model.savedURL, Application.shared.canOpenURL(savedURL) {
                            Application.shared.open(savedURL)
                        }
                    }
                )
            }
        }
    }
#endif
