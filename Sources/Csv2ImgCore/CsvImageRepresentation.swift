import CoreGraphics
import Foundation

public struct CsvImageRepresentation: Equatable {
    let width: Int
    let height: Int
    let backgroundColor: CGColor
    let fontSize: CGFloat
    let columns: [ColumnRepresentation]
    let rows: [RowRepresentation]

    struct ColumnRepresentation: Equatable {
        let name: String
        let style: Csv.Column.Style
        let frame: CGRect
    }

    struct RowRepresentation: Equatable {
        let values: [String]
        let frames: [CGRect]
    }
}
