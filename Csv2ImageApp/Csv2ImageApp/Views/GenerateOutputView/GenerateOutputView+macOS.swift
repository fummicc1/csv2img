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

    private let availableEncodingType: [String.Encoding] = [
        .utf8,
        .utf16,
        .utf32,
        .shiftJIS,
        .ascii,
    ]

    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if !model.state.isLoading {
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
                        GeneratePreviewView(
                            model: model,
                            size: .constant(
                                CGSize(
                                    width: proxy.size.width * 0.7,
                                    height: proxy.size.height * 0.7
                                )
                            )
                        )
                        .frame(
                            width: proxy.size.width * 0.7,
                            height: proxy.size.height * 0.7
                        )
                        Spacer()
                        HStack {
                            Picker(selection: Binding(get: {
                                model.state.exportType
                            }, set: { exportType, _ in
                                model.update(keyPath: \.exportType, value: exportType)
                            })) {
                                CText("png").tag(Csv.ExportType.png)
                                CText("pdf").tag(Csv.ExportType.pdf)
                            } label: {
                                CText("Export Type")
                            }
                            .padding()
                            .pickerStyle(.radioGroup)
                            .background(Asset.backgroundColor.swiftUIColor)
                            .padding()

                            let encodingInfo = model.state.encoding.description
                            Menu("Encode Type: \(encodingInfo)") {
                                ForEach(availableEncodingType) { encoding in
                                    Button {
                                        model.update(keyPath: \.encoding, value: encoding)
                                    } label: {
                                        Text(encoding.description)
                                    }

                                }
                            }

                            Spacer()
                            CButton.labeled("Save", role: .primary) {
                                model.save()
                            }
                        }.padding()
                    }
                    .background(Asset.lightAccentColor.swiftUIColor)
                } else {
                    VStack {
                        Spacer()
                        ProgressView(value: model.state.progress) {
                            CText("Loading...", font: .largeTitle)
                        }
                        .padding()
                        .progressViewStyle(.linear)
                        Spacer()
                    }
                    .background(Asset.lightAccentColor.swiftUIColor)
                }
                VStack {
                    Spacer()
                    VStack {
                        CText(model.state.errorMessage ?? "", foregroundColor: .red)
                            .padding()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Asset.secondaryBackgroundColor.swiftUIColor)
                    .cornerRadius(12)
                    .padding()
                }
                .opacity(model.state.errorMessage != nil ? 1 : 0)
                .animation(.easeInOut, value: model.state.errorMessage)
                .onChange(of: model.state.errorMessage, perform: { errorMessage in
                    if errorMessage != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                model.clearError()
                            }
                        }
                    }
                })
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
