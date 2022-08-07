//
//  RootView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct RootView: View {

    @State private var selectedCsv: SelectedCsvState?

    var body: some View {
        if let selectedCsv = selectedCsv {
            GenerateOutputView(
                model: GenerateOutputModel(
                    url: selectedCsv.url,
                    urlType: selectedCsv.fileType
                ),
                backToPreviousPage: $selectedCsv.isNil()
            ).transition(.opacity.animation(.easeInOut))
        } else {
            SelectCsvView(selectedCsv: $selectedCsv, model: SelectCsvModel())
                .transition(.move(edge: .leading).animation(.easeInOut))
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
