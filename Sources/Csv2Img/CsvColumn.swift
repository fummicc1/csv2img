//
//  CsvColumn.swift
//
//
//  Created by Fumiya Tanaka on 2022/08/26.
//

import CoreGraphics
import Foundation

extension Csv {
    /// Column (a head line)
    ///
    /// Column is the first one of vertically separated groups.
    ///
    /// following groups are treated as ``Row``.
    ///
    /// eg.
    ///
    /// 1 2 3 4
    ///
    /// 5 6 7 8
    /// →Column is [1, 2, 3, 4] and Row is [5, 6, 7, 8].
    ///
    /// Because this class is usually initialized via ``Csv``, you do not have to take care about ``Column`` in detail.
    public struct Column: Sendable {
        public var name: Name
        public var style: Style

        public init(
            name: Name,
            style: Style
        ) {
            self.name = name
            self.style = style
        }
    }
}

extension Csv.Column {
    /// ``Style`` decides the appearance of certain ``Column`` group.
    public struct Style: Sendable {
        /// `color` is a ``CGColor`` corresponding to textColor which is used when drawing
        public var color: CGColor
        /// `applyOnlyColumn` determines whether this style affects both `Column` and `Row` or not.
        /// Default value of `applyOnlyColumn` is false, which means ``Style`` is also applied to ``Row``.
        public var applyOnlyColumn: Bool

        public init(
            color: CGColor,
            applyOnlyColumn: Bool = false
        ) {
            self.color = color
            self.applyOnlyColumn = applyOnlyColumn
        }

        public static func random(
            count: Int
        ) -> [Style] {
            var styles: [Style] = []
            let saturation = 80.0 / 100.0
            let value = 80.0 / 100.0
            var hue: Double = 0.5
            for _ in 0..<count {
                let color: Color
                if let random = (0..<360).randomElement() {
                    hue =
                        Double(
                            random
                        ) / 360
                    color = Color(
                        hue: hue,
                        saturation: saturation,
                        brightness: value,
                        alpha: 1
                    )
                } else {
                    color = Color(
                        hue: 1 - hue,
                        saturation: saturation,
                        brightness: value,
                        alpha: 1
                    )
                }
                let style = Style(
                    color: color.cgColor
                )
                styles.append(
                    style
                )
            }
            return styles
        }

        public static func random() -> Style {
            random(
                count: 1
            ).first!
        }
    }
}

extension Csv.Column {
    /// ``Name`` is just a typealias of ``String``
    public typealias Name = String
}
