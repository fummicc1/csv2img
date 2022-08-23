import Foundation

public protocol Maker {
    associatedtype Exportable: CsvExportable

    var maximumRowCount: Int? { get }

    func make(columns: [Csv.ColumnName], rows: [Csv.Row]) throws -> Exportable
    func setFontSize(_ size: CGFloat)
}
