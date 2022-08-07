//
//  SelectCsvView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img


struct SelectCsvView: View {

    @Binding var selectedImageUrl: URL?
    @ObservedObject var model: SelectCsvModel

    var body: some View {
        #if os(macOS)
        SelectCsvView_macOS(selectedImageUrl: _selectedImageUrl, model: model)
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
