import CoreFoundation

public protocol Maker {
    associatedtype Exportable: CsvExportable
    func make(csv: Csv) throws -> Exportable
    func setFontSize(_ size: CGFloat)
}
