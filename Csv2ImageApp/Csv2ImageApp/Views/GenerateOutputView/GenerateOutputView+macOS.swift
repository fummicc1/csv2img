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
        NavigationSplitView(sidebar: {
            List {
                Section("Export Type") {
                    Picker(selection: Binding(get: {
                        model.state.exportType
                    }, set: { exportType, _ in
                        model.update(keyPath: \.exportType, value: exportType)
                    })) {
                        CText("png").tag(Csv.ExportType.png)
                        CText("pdf").tag(Csv.ExportType.pdf)
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.radioGroup)
                }
                Section("Encoding") {
                    let encodingInfo = model.state.encoding.description
                    Menu(encodingInfo) {
                        ForEach(availableEncodingType) { encoding in
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
                    let encodingInfo = model.state.size.rawValue
                    Menu(encodingInfo) {
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
                    let orientation = model.state.orientation.rawValue
                    Menu(orientation) {
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
            VStack {
                CButton.labeled("Save", role: .primary) {
                    model.save()
                }
            }.padding()
        }, detail: {
            if model.state.isLoading {
                loadingContent
            } else {
                VStack(alignment: .center) {
                    GeometryReader { proxy in
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
            }
        })
        .background(Asset.lightAccentColor.swiftUIColor)

    }

    var loadingContent: some View {
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

    var errorContent: some View {
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
