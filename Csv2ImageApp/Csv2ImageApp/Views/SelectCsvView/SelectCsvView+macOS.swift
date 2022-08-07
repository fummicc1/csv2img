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
    @Binding var selectedCsv: SelectedCsvState?
    @ObservedObject var model: SelectCsvModel

    var body: some View {
        BrandingFrameView {
            VStack {
                CText("Drop csv file here", font: .largeTitle)

                Spacer().frame(height: 32)
                CButton.labeled("Alternatively, Choose from Finder") {
                    Task {
                        do {
                            guard let url = try await model.selectFileOnDisk() else {
                                return
                            }
                            withAnimation {
                                selectedCsv = SelectedCsvState(fileType: .local, url: url)
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else {
                return false
            }
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, error in
                if let error = error {
                    print(error)
                    return
                }
                guard let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true) else {
                    return
                }
                if url.lastPathComponent.contains(".csv") {
                    DispatchQueue.main.async {
                        withAnimation {
                            selectedCsv = SelectedCsvState(fileType: .local, url: url)
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
            selectedCsv: .constant(nil),
            model: SelectCsvModel()
        )
    }
}
#endif
