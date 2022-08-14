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
            CButton.labeled("Select Csv File") {
                Task {
                    await model.selectFileOnDisk()
                }
            }
        }
    }
}

struct SelectCsvView_iOS_Previews: PreviewProvider {
    static var previews: some View {
        SelectCsvView_iOS(model: SelectCsvModel())
    }
}
#endif
