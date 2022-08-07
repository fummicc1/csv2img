import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import PDFKit

/** Csv data structure

 ``Csv`` is a struct to store information to parse csv into table.

 ``Csv`` automatically recognize first row as column and others as rows.

 ```swift
 let rawCsv = """
 a,b,c
 1,2,3
 4,5,6
 7,8,9
 10,11,12
 """
 let csv = Csv.fromString(rawCsv)
 Output:
 | a  | b  | c  |
 | 1  | 2  | 3  |
 | 4  | 5  | 6  |
 | 7  | 8  | 9  |
 | 10 | 11 | 12 |
 ```
*/
public class Csv {

    /// initialization
    ///
    /// `separator` is applied to each row and generate items per row.
    /// `columnNames` is array of column whose type is `String`.
    /// `Row` is array of row whose type is ``Row``
    public init(
        separator: String=",",
        rawString: String,
        columnNames: [Csv.ColumnName],
        rows: [Csv.Row],
        exportType: ExportType = .png
    ) {
        self.imageMarker = ImageMaker(fontSize: 12)
        self.pdfMarker = PdfMaker(
            fontSize: 12,
            metadata: PDFMetadata(
                author: "Author",
                title: "Title"
            )
        )
        self.separator = separator
        self.rawString = rawString
        self.columnNames = columnNames
        self.rows = rows
        self.exportType = exportType
    }

    /// an separator applied to each row and column.
    public var separator: String
    /// an array of column name with type ``ColumnName``.
    public var columnNames: [ColumnName]
    /// an array of row whose type is ``Row`.
    public var rows: [Row]
    /// ``ImageMarker`` has responsibility to generate png-image from csv.
    private let imageMarker: ImageMaker

    /// ``PdfMaker`` has responsibility to generate pdf-image from csv.
    private let pdfMarker: PdfMaker

    /// `rawString` is original String read from Resource (either Local or Network).
    public var rawString: String

    /// `exportType` determines export type. Please choose ``ExportType.png`` or ``ExportType.pdf``.
    public var exportType: ExportType
}

extension Csv {
    /**
    `ExportType` is a enum that expresses
     */
    public enum ExportType: String, Hashable {
        /// `png` output
        case png
        /// `pdf` output (Work In Progress)
        case pdf

        public var fileExtension: String {
            self.rawValue
        }

        public var utType: UTType {
            switch self {
            case .png:
                return .png
            case .pdf:
                return .pdf
            }
        }
    }
}

extension Csv {
    /// Row (a line)
    ///
    /// Row is hrizontally separated group except first line.
    ///
    /// First line is treated as ``ColumnName``.
    ///
    /// eg.
    ///
    /// 1 2 3 4
    ///
    /// 5 6 7 8
    ///
    /// →Row is [5, 6, 7, 8].
    ///
    ///
    /// Because this class is usually initialized via ``Csv``, you do not have to take care about ``Row`` in detail.
    ///
    public struct Row {

        public init(index: Int, values: [String]) {
            self.index = index
            self.values = values
        }

        public var index: Int
        public var values: [String]

    }

    /// ColumnName (a head line)
    ///
    /// Column is at the first group of hrizontally separated groups.
    ///
    /// following lines are treated as ``Row``.
    ///
    /// eg.
    ///
    /// 1 2 3 4
    ///
    /// 5 6 7 8
    /// →ColumnName is [1, 2, 3, 4] and Row is [5, 6, 7, 8].
    ///
    /// Because this class is usually initialized via ``Csv``, you do not have to take care about ``ColumnName`` in detail.
    ///
    public struct ColumnName {

        public init(value: String) {
            self.value = value
        }

        public var value: String
    }
}

extension Csv {

    /// `Error` related with Csv implmentation.
    public enum Error: Swift.Error {
        /// Specified network url is invalid or failed to download csv data.
        case invalidDownloadResource(url: String, data: Data)
        /// Specified local url is invalid (file may not exist).
        case invalidLocalResource(url: String, data: Data)
        /// If file is not accessible due to security issue.
        case cannotAccessFile(url: String)
        /// given `exportType` is invalid.
        case invalidExportType(ExportType)
    }

    /// Generate `Csv` from `String` data.
    ///
    /// You cloud call `Csv.fromString` if you can own raw-CSV data.
    ///
    /// ```swift
    /// let rawCsv = """
    /// a,b,c
    /// 1,2,3
    /// 4,5,6
    /// 7,8,9
    /// 10,11,12
    /// """
    /// let csv = Csv.fromString(rawCsv)
    /// Output:
    /// | a  | b  | c  |
    /// | 1  | 2  | 3  |
    /// | 4  | 5  | 6  |
    /// | 7  | 8  | 9  |
    /// | 10 | 11 | 12 |
    ///```
    ///
    /// You cloud change separator by giving value to `separator` parameter.
    ///
    ///```swift
    /// let dotSeparated = """
    /// a.b.c
    /// 1.2.3
    /// 4.5.6
    /// 7.8.9
    /// """
    /// let csv = Csv.fromString(dotSeparated, separator: ".")
    /// Output:
    /// | a  | b  | c  |
    /// | 1  | 2  | 3  |
    /// | 4  | 5  | 6  |
    /// | 7  | 8  | 9  |
    /// | 10 | 11 | 12 |
    /// ```
    ///
    /// If certain row-item is very long, you could trim it with `maxLength`-th length.
    ///
    ///```swift
    /// let longCsv = """
    /// a.b.c
    /// 1.2.33333333333333333333333333333333333333333
    /// 4.5.6
    /// 7.8.9
    /// """
    /// let csv = Csv.fromString(dotSeparated, separator: ".", maxLength: 7)
    /// Output:
    /// | a  | b  | c        |
    /// | 1  | 2  | 3333333  |
    /// | 4  | 5  | 6        |
    /// | 7  | 8  | 9        |
    /// | 10 | 11 | 12       |
    /// ```
    ///
    /// - Parameters:
    ///     - str: Row String
    ///     - separator: Default separator in a row is `","`. You cloud change it by giving separator to `separator` parameter.
    ///     - maxLength: Default value is nil. if `maxLength` is not nil, every row-item length is limited by `maxLength`.
    public static func fromString(_ str: String, separator: String = ",", maxLength: Int? = nil) -> Csv {
        let csv = Csv(
            separator: separator,
            rawString: str,
            columnNames: [],
            rows: []
        )
        var lines = str.components(separatedBy: CharacterSet(charactersIn: "\r\n"))
        lines = lines.filter({ $0 != "" })
        for (i, line) in lines.enumerated() {
            var items = line
                .split(separator: Character(separator), omittingEmptySubsequences: false)
                .map({ String($0) })
            if i == 0 {
                csv.columnNames = items.enumerated().compactMap({ (index, name) in
                    return ColumnName(value: name)
                })
            } else {
                items = items.enumerated().compactMap { (index, item) in
                    let str: String
                    if let maxLength = maxLength, item.count > maxLength {
                        print("Too long value: \(item), it is shortened.")
                        str = String(item.prefix(maxLength)) + "..."
                    } else {
                        str = item
                    }
                    return str
                }
                let row = Row(
                    index: i,
                    values: items
                )
                csv.rows.append(row)
            }
        }
        return csv
    }

    /// Generate `Csv` from network url (like `HTTPS`).
    ///
    /// - Parameters:
    ///     - url: network url, commonly `HTTPS` schema.
    ///     - separator: Default separator in a row is `","`. You cloud change it by giving separator to `separator` parameter.
    public static func fromURL(_ url: URL, separator: String = ",") throws -> Csv {
        let data = try Data(contentsOf: url)
        if let str = String(data: data, encoding: .utf8) {
            return .fromString(str)
        }
        if let str = String(data: data, encoding: .ascii) {
            return .fromString(str)
        }
        throw Error.invalidDownloadResource(url: url.absoluteString, data: data)
    }

    /// Generate `Csv` from local url (like `file://Users/...`).
    ///
    /// - Parameters:
    ///     - file: local url, commonly `file://` schema. Relative-path is not enable, please specify by absolute-path rule.
    ///     - separator: Default separator in a row is `","`. You cloud change it by giving separator to `separator` parameter.
    ///     - checkAccessSecurityScope: This flag is effective to only macOS. If you want to check local-file is securely accessible from this app, make this flat `true`. Default value if `false` which does not check the file access-security-scope.
    public static func fromFile(
        _ file: URL,
        separator: String = ",",
        checkAccessSecurityScope: Bool = false
    ) throws -> Csv {
        // https://www.hackingwithswift.com/forums/swift/accessing-files-from-the-files-app/8203
        if !checkAccessSecurityScope || file.startAccessingSecurityScopedResource() {
            let data = try Data(contentsOf: file)
            if let str = String(data: data, encoding: .utf8) {
                return .fromString(str)
            }
            if let str = String(data: data, encoding: .ascii) {
                return .fromString(str)
            }
            throw Error.invalidLocalResource(url: file.absoluteString, data: data)
        } else {
            throw Error.cannotAccessFile(url: file.absoluteString)
        }
    }

    /**
     Generate Output (file-type is determined by `exportType` parameter)
     - Parameters:
        - fontSize: Determine the fontsize of characters in output-table image.
        - exportType:Determine file-extension. Type is ``ExportType`` and default value is ``ExportType.png``.
     - Note:
     `fontSize` determines the size of output image and it can be as large as you want. Please consider the case that output image is too large to open image. Although output image becomes large, it is recommended to set fontSize amply enough (maybe larger than `12pt`) to see image clearly.
     - Returns: ``CsvExportable``. (either ``CGImage`` or  ``PdfDocument``).
     - Throws: Throws ``ImageMakingError``.
     */
    public func generate(
        fontSize: CGFloat? = nil,
        exportType: ExportType = .png
    ) throws -> AnyCsvExportable {
        self.exportType = exportType
        var maker: Any?
        switch exportType {
        case .png:
            maker = self.imageMarker
        case .pdf:
            maker = self.pdfMarker
        }
        if let maker = maker as? ImageMaker {
            if let fontSize = fontSize {
                maker.setFontSize(fontSize)
            }
            return AnyCsvExportable(try maker.make(csv: self))
        } else if let maker = maker as? PdfMaker {
            if let fontSize = fontSize {
                maker.setFontSize(fontSize)
            }
            return AnyCsvExportable(try maker.make(csv: self))
        }
        throw Error.invalidExportType(exportType)
    }

    /**
     Generate Data
     - Parameters:
        - fontSize: Determine the fontsize of characters in output-table image.
     - Note:
     `fontSize` determines the size of output image and it can be as large as you want. Please consider the case that output image is too large to open image. Although output image becomes large, it is recommended to set fontSize amply enough (maybe larger than `12pt`) to see image clearly.
     - Returns: `Optional<Data>`
     */
    public func pngData(fontSize: CGFloat? = nil) -> Data? {
        if let fontSize = fontSize {
            imageMarker.setFontSize(fontSize)
        }
        let image = try? imageMarker.make(csv: self)
        return image?.convertToData()
    }

    /**
     - parameters:
        - to url: local file path where [png, pdf] image will be saved.
     - Returns: If saving csv image to file, returns `true`. Otherwise, return `False`.
     */
    public func write(to url: URL) -> Data? {
        let data: Data?
        if exportType == .png {
            data = imageMarker.latestOutput?.convertToData()
        } else if exportType == .pdf {
            pdfMarker.latestOutput?.write(to: url)
            return pdfMarker.latestOutput?.dataRepresentation()
        } else {
            data = nil
        }
        guard let data = data else {
            return nil
        }
        do {
            if !FileManager.default.fileExists(atPath: url.absoluteString) {
                FileManager.default.createFile(atPath: url.absoluteString, contents: data)
            } else {
                try data.write(to: url)
            }
            return data
        } catch {
            print(error)
            return nil
        }
    }
}
