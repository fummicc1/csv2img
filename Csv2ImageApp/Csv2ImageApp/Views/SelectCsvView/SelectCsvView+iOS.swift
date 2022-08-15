//
//  SelectCsvView+iOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

#if os(iOS)
struct SelectCsvView_iOS: View {

    @StateObject var model: SelectCsvModel

    var body: some View {
        BrandingFrameView {
            VStack {
                CButton.labeled("Select Csv File") {
                    Task {
                        await model.selectFileOnDisk()
                    }
                }
                Divider().padding()
                CText("Alternately, please input csv file url on the Internet.")
                HStack {
                    TextField("example: https://bit.ly/3c2leMC", text: $model.networkUrlText)
                        .textFieldStyle(.roundedBorder)
                    Spacer()
                    if !model.networkUrlText.isEmpty {
                        CButton.icon(systemName: "xmark") {
                            model.networkUrlText = ""
                        }
                    }
                    CButton.labeled("OK") {
                        Task {
                            await model.selectFileOnTheInternet()
                        }
                    }
                    Spacer().frame(width: 16)
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $model.error.isNotNil(), actions: {
            Button("Close") {
                model.error = nil
            }
        }, message: {
            Text(model.error ?? "")
        })
    }
}

struct SelectCsvView_iOS_Previews: PreviewProvider {
    static var previews: some View {
        SelectCsvView_iOS(model: SelectCsvModel())
    }
}
#endif
