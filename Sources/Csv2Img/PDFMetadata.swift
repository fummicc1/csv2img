import Foundation

/// ``PDFMetadata`` is a struct which stores Metadata about output-pdf.
public struct PDFMetadata {
    public init(author: String, title: String) {
        self.author = author
        self.title = title
    }

    /// `author`. author of pdf.
    public var author: String
    /// `title`. pdf-title.
    public var title: String
}
