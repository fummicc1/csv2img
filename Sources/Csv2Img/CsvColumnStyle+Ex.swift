//
//  CsvColumnStyle+Ex.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/26.
//

import Foundation


extension Csv.Column.Style {

    func normalColor() -> Any {
        #if os(macOS)
        let color: Any = Color.labelColor
        #elseif os(iOS)
        let color: Any = Color.label.cgColor
        #endif
        return color
    }

    func displayableColor() -> Any {
        if applyOnlyColumn {
            return normalColor()
        }
        #if os(macOS)
        // On macOS, foregroundColor in NSAttributedString should be `NSColor` type.
        if let _color = Color(cgColor: color) {
            return _color
        } else {
            return color
        }
        #elseif os(iOS)
        return color
        #endif
    }
}
