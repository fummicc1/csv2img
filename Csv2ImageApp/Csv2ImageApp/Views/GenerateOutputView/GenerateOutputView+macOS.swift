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
            NavigationView {
                HSplitView {
                    List {
                        Section("Settings") {
                            Picker("Encoding", selection: $model.encoding) {
                                ForEach(availableEncodingType, id: \.self) { encoding in
                                    Text(encoding.description).tag(encoding)
                                }
                            }
                            // Add more settings here as needed
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

                    VStack {
                        GeneratePreviewView(
                            model: model,
                            size: .constant(
                                .init(
                                    width: 480,
                                    height: 360
                                )
                            )
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        HStack {
                            Button("Generate") {
                                // Add generation logic here
                            }
                            .keyboardShortcut(.defaultAction)

                            Button("Save As...") {
                                // Add save logic here
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
