import CoreFoundation
import CoreGraphics
import PDFKit

public protocol CsvExportable {
}

extension CGImage: CsvExportable { }
extension Data: CsvExportable { }
extension PDFDocument: CsvExportable { }
