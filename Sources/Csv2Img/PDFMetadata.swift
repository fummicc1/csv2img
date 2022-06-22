import Foundation

public struct PDFMetadata {
    public init(author: String, title: String) {
        self.author = author
        self.title = title
    }

    public var author: String
    public var title: String
}
