//
//  CText.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct CText: View {

    let text: String
    let isBold: Bool
    let font: Font

    init(_ text: String, isBold: Bool = true, font: Font = .body) {
        self.text = text
        self.isBold = isBold
        self.font = font
    }

    var body: some View {
        if isBold {
            Text(text)
                .bold()
                .font(font)
                .foregroundColor(Asset.textColor.swiftUIColor)
        } else {
            Text(text)
                .bold()
                .font(font)
                .foregroundColor(Asset.textColor.swiftUIColor)
        }
    }
}

struct CText_Previews: PreviewProvider {
    static var previews: some View {
        CText("Hello")
    }
}
