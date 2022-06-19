//
//  CsvViewer.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/20.
//

import SwiftUI

struct CsvViewer: View {

    let img: CGImage

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                Image(img, scale: 1, orientation: .up, label: Text("Output Image"))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: proxy.size.width * 0.6)
            }
        }
    }
}
