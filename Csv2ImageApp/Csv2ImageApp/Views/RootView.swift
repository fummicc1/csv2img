//
//  RootView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct RootView: View {

    @State private var selectedImageUrl: URL?

    var body: some View {
        SelectCsvView(selectedImageUrl: $selectedImageUrl, model: SelectCsvModel())
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
