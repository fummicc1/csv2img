//
//  CButton.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

struct CButton: View {

    enum Role: Hashable {
        case primary
        case secondary
        case normal

        var background: Color {
            switch self {
            case .primary:
                return Asset.accentColor.swiftUIColor
            case .secondary:
                return Asset.secondaryColor.swiftUIColor
            case .normal:
                return Asset.backgroundColor.swiftUIColor
            }
        }
    }

    let content: () -> AnyView
    var hPadding: CGFloat
    var vPadding: CGFloat
    var role: Role = .normal

    let onPressed: () -> Void

    init(
        content: @escaping () -> AnyView,
        hPadding: CGFloat = 12,
        vPadding: CGFloat = 8,
        role: Role,
        onPressed: @escaping () -> Void
    ) {
        self.content = content
        self.hPadding = hPadding
        self.vPadding = vPadding
        self.role = role
        self.onPressed = onPressed
    }

    var body: some View {
        Button {
            onPressed()
        } label: {
            content()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, hPadding)
        .padding(.vertical, vPadding)
        .background(role.background)
        .cornerRadius(12)
    }

    static func labeled(
        _ text: String,
        isBold: Bool = true,
        font: Font = .body,
        hPadding: CGFloat = 12,
        vPadding: CGFloat = 8,
        role: Role = .normal,
        onPressed: @escaping () -> Void
    ) -> CButton {
        CButton(
            content: {
                AnyView(CText(text, isBold: isBold, font: font))
            },
            hPadding: hPadding,
            vPadding: vPadding,
            role: role,
            onPressed: onPressed
        )
    }

    static func icon(
        systemName: String,
        font: Font = .body,
        hPadding: CGFloat = 12,
        vPadding: CGFloat = 8,
        role: Role = .normal,
        onPressed: @escaping () -> Void
    ) -> CButton {
        CButton(
            content: {
                AnyView(
                    Image(systemName: systemName)
                        .foregroundColor(Asset.textColor.swiftUIColor)
                        .font(font)
                )
            },
            hPadding: hPadding,
            vPadding: vPadding,
            role: role,
            onPressed: onPressed
        )
    }
}

struct CButton_Previews: PreviewProvider {
    static var previews: some View {
        CButton.labeled("Hello", onPressed: {})
    }
}
