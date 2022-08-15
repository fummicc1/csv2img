//
//  BrandingFrameView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct BrandingFrameView<Content: View>: View {

    let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [
                        Asset.lightAccentColor.swiftUIColor,
                        Asset.accentColor.swiftUIColor,
                    ],
                    center: .init(x: 0.5, y: 0.5), startRadius: 8, endRadius: proxy.size.width / 2
                )
                .ignoresSafeArea()
                content()
            }
        }
    }
}

struct BrandingFrameView_Previews: PreviewProvider {
    static var previews: some View {
        BrandingFrameView {
            Spacer().frame(width: 300, height: 300)
        }
    }
}
