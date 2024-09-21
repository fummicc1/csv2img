//
//  GenerateOutputView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct GenerateOutputView: View {

    @StateObject var model: GenerateOutputModel
    @Binding var backToPreviousPage: Bool

    var body: some View {
        #if os(iOS)
            GenerateOutputView_iOS(
                model: model,
                backToPreviousPage: _backToPreviousPage
            )
        #elseif os(macOS)
            GenerateOutputView_macOS(
                model: model,
                backToPreviousPage: _backToPreviousPage
            )
        #endif

    }
}

struct GenerateOutputView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateOutputView(
            model: GenerateOutputModel(
                url: URL(string: "https://via.placeholder.com/150")!,
                urlType: .network
            ),
            backToPreviousPage: .constant(false)
        )
    }
}
