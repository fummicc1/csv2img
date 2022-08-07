//
//  CButton.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct CButton: View {

    let content: () -> AnyView

    let onPressed: () -> Void

    var body: some View {
        Button {
            onPressed()
        } label: {
            content()
        }
        .buttonStyle(.plain)
        .padding()
        .background(Asset.backgroundColor.swiftUIColor)
        .cornerRadius(12)
    }

    static func labeled(_ text: String, isBold: Bool = true, font: Font = .body, onPressed: @escaping () -> Void) -> CButton {
        CButton(
            content: {
                AnyView(CText(text, isBold: isBold, font: font))
            },
            onPressed: onPressed
        )
    }
}

struct CButton_Previews: PreviewProvider {
    static var previews: some View {
        CButton.labeled("Hello", onPressed: { })
    }
}
