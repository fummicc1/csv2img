//
//  SelectCsvView+macOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
    struct SelectCsvView_macOS: View {
        @State private var isTargeted: Bool = false
        @StateObject var model: SelectCsvModel

        var body: some View {
            BrandingFrameView {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.secondary)

                    Text("Drop CSV File Here")
                        .font(.system(size: 24, weight: .medium))

                    Text("or")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)

                    Button("Choose from Finder") {
                        Task {
                            await model.selectFileOnDisk()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
                        .background(Color.secondary.opacity(0.05))
                )
            }
            .frame(minWidth: 400, minHeight: 300)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else {
                    return false
                }
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
                    data, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let data = data as? Data,
                        let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true)
                    else {
                        return
                    }
                    if url.pathExtension.lowercased() == "csv" {
                        DispatchQueue.main.async {
                            withAnimation {
                                model.selectedCsv = SelectedCsvState(fileType: .local, url: url)
                            }
                        }
                    }
                }
                return true
            }
        }
    }

    struct SelectCsvView_macOS_Previews: PreviewProvider {
        static var previews: some View {
            SelectCsvView_macOS(
                model: SelectCsvModel()
            )
        }
    }
#endif
