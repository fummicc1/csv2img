import Foundation

public protocol Maker: Sendable {
    associatedtype Exportable: CsvExportable

    var maximumRowCount: Int? {
        get
    }
    
    func make(
        columns: [Csv.Column],
        rows: [Csv.Row],
        progress: @escaping @Sendable (
            Double
        ) -> Void
    ) throws -> Exportable
    func set(
        fontSize size: Double
    )
}
