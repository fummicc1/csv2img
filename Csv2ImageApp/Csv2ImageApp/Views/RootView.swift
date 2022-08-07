//
//  RootView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct RootView: View {

    @State private var selectedCsv: SelectedCsvInfo?

    var body: some View {
        if let selectedCsv {
            GenerateOutputView(
                model: GenerateOutputModel(
                    url: selectedCsv.url,
                    urlType: selectedCsv.fileType
                )
            ).transition(.opacity)
        } else {
            SelectCsvView(selectedCsv: $selectedCsv, model: SelectCsvModel())
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
