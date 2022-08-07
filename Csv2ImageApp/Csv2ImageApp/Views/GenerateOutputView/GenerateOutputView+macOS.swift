//
//  GenerateOutputView+macOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

#if os(macOS)
struct GenerateOutputView_macOS: View {

    @ObservedObject var model: GenerateOutputModel

    var body: some View {
        Text("Hello, World!")
    }
}

struct GenerateOutputView_macOS_Previews: PreviewProvider {
    static var previews: some View {
        GenerateOutputView_macOS(
            model: GenerateOutputModel(
                url: URL(string: "https://via.placeholder.com/150")!,
                urlType: .network
            )
        )
    }
}
#endif
