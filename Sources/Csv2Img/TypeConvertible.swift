import CoreFoundation
import CoreGraphics
import PDFKit

public protocol CsvExportable: Sendable {
}

public final class AnyCsvExportable: CsvExportable {

    public let base: CsvExportable

    public init(_ csvExportable: CsvExportable) {
        self.base = csvExportable
    }
}

extension CGImage: CsvExportable { }
extension Data: CsvExportable { }
extension PDFDocument: @unchecked Sendable {}
extension PDFDocument: CsvExportable { }
