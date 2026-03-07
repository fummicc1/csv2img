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

    /// `subject`. subject of the document.
    public var subject: String?
    /// `keywords`. keywords associated with the document.
    public var keywords: [String]?
    /// `creationDate`. creation date of the document.
    public var creationDate: Date?
    /// `creator`. application that created the document.
    public var creator: String?

    public init(
        author: String? = nil,
        title: String? = nil,
        size: PdfSize? = nil,
        orientation: PdfSize.Orientation = .portrait,
        subject: String? = nil,
        keywords: [String]? = nil,
        creationDate: Date? = nil,
        creator: String? = "Csv2Img"
    ) {
        self.author = author
        self.title = title
        self.size = size
        self.orientation = orientation
        self.subject = subject
        self.keywords = keywords
        self.creationDate = creationDate
        self.creator = creator
    }
}
