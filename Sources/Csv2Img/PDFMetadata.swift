import Foundation

/// ``PDFMetadata`` is a struct which stores Metadata about output-pdf.
public struct PDFMetadata {

    /// `author`. author of document.
    public var author: String?
    /// `title`. title of document.
    public var title: String?

    /**
     - specify output pdf size with ``PdfSize``.
     */
    public var size: PdfSize?
    public var orientation: PdfSize.Orientation

    public init(
        author: String? = nil,
        title: String? = nil,
        size: PdfSize? = nil,
        orientation: PdfSize.Orientation = .portrait
    ) {
        self.author = author
        self.title = title
        self.size = size
        self.orientation = orientation
    }
}
