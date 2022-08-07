//
//  GenerateOutputView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI


struct GenerateOutputView: View {

    @ObservedObject var model: GenerateOutputModel

    var body: some View {
        #if os(iOS)
        GenerateOutputView_iOS()
        #elseif os(macOS)
        GenerateOutputView_macOS(model: model)
        #endif
    }
}

struct GenerateOutputView_Previews: PreviewProvider {
    static var previews: some View {
        GenerateOutputView(
            model: GenerateOutputModel(
                url: URL(string: "https://via.placeholder.com/150")!,
                urlType: .network
            )
        )
    }
}
