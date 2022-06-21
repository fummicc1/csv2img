import CoreFoundation
import CoreGraphics
import PDFKit

public protocol CsvExportable {
}

public class AnyCsvExportable: CsvExportable {

    public var base: CsvExportable

    public init(_ csvExportable: CsvExportable) {
        self.base = csvExportable
    }
}

extension CGImage: CsvExportable { }
extension Data: CsvExportable { }
extension PDFDocument: CsvExportable { }
