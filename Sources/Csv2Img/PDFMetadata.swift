import Foundation

/// ``PDFMetadata`` is a struct which stores Metadata about output-pdf.
public struct PDFMetadata {
    public init(
        author: String,
        title: String
    ) {
        self.author = author
        self.title = title
    }

    /// `author`. author of document.
    public var author: String
    /// `title`. title of document.
    public var title: String
}
