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

        @Bindable var model: GenerateOutputModel
        @Binding var backToPreviousPage: Bool
        @State private var succeedSavingOutput: Bool = false

        private let availableEncodingType: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf32,
            .shiftJIS,
            .ascii,
        ]

        @Environment(\.dismiss) var dismiss

        var body: some View {
            NavigationView {
                HSplitView {
                    List {
                        Section("Settings") {
                            Picker("Export Type", selection: $model.state.exportType) {
                                ForEach(Csv.ExportType.allCases, id: \.self) { exportType in
                                    Text(exportType.fileExtension).tag(exportType)
                                }
                            }
                            Picker("Encoding", selection: $model.state.encoding) {
                                ForEach(availableEncodingType, id: \.self) { encoding in
                                    Text(encoding.description).tag(encoding)
                                }
                            }
                            if model.state.exportType == .pdf {
                                Picker("PDF Size", selection: $model.state.size) {
                                    ForEach(PdfSize.allCases, id: \.self) { pdfSize in
                                        Text(pdfSize.rawValue).tag(pdfSize)
                                    }
                                }
                                Picker("PDF Orientation", selection: $model.state.orientation) {
                                    ForEach(PdfSize.Orientation.allCases, id: \.self) {
                                        orientation in
                                        Text(orientation.rawValue).tag(orientation)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

                    VStack {
                        GeometryReader(content: { proxy in
                            GeneratePreviewView(
                                model: model
                            )
                        })

                        HStack {
                            Button("Save As...") {
                                succeedSavingOutput = model.save()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Generate Output")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 800, minHeight: 600)
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
                        if let savedURL = model.savedURL, NSWorkspace.shared.open(savedURL) {
                            NSWorkspace.shared.open(savedURL)
                        }
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
