//
//  SelectCsvView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img


struct SelectCsvView: View {

    @Binding var selectedCsv: SelectedCsvState?
    @StateObject var model: SelectCsvModel

    var body: some View {
        #if os(macOS)
        SelectCsvView_macOS(selectedCsv: _selectedCsv, model: model)
        #elseif os(iOS)
        SelectCsvView_iOS()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        fatalError()
    }
}
