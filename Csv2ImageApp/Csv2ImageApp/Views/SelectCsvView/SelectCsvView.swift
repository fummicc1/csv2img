//
//  SelectCsvView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import Csv2Img
import SwiftUI

struct SelectCsvView: View {

    @Binding var selectedCsv: SelectedCsvState?
    @StateObject var model: SelectCsvModel

    var body: some View {
        Group {
            #if os(macOS)
                SelectCsvView_macOS(model: model)
            #elseif os(iOS)
                SelectCsvView_iOS(model: model)
            #endif
        }
        .onReceive(model.$selectedCsv) { selectedCsv in
            self.selectedCsv = selectedCsv
        }
    }
}
