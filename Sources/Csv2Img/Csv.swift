import Foundation

public struct Csv {
    public init(separator: String, columnNames: [Csv.ColumnName], rows: [Csv.Row]) {
        self.separator = separator
        self.columnNames = columnNames
        self.rows = rows
    }

    public var separator: String
    public var columnNames: [ColumnName]
    public var rows: [Row]
}

extension Csv {
    public struct Row {

        public init(index: Int, values: [String]) {
            self.index = index
            self.values = values
        }

        public var index: Int
        public var values: [String]

    }

    public struct ColumnName {

        public init(value: String) {
            self.value = value
        }

        public var value: String
    }
}

extension Csv {

    public enum Error: Swift.Error {
        case invalidDownloadResource(url: String, data: Data)
        case invalidLocalResource(url: String, data: Data)
    }

    public static func fromString(_ str: String, separator: String = ",", maxLength: Int? = nil) -> Csv {
        var csv = Csv(
            separator: separator,
            columnNames: [],
            rows: []
        )
        let lines = str.split(separator: "\n")
        var ignoredIndexes: [Int] = []
        for (i, line) in lines.enumerated() {
            var items = line
                .split(separator: Character(separator), omittingEmptySubsequences: false)
                .map({ String($0) })
            if i == 0 {
                csv.columnNames = items.enumerated().compactMap({ (index, name) in
                    if name.isEmpty {
                        ignoredIndexes.append(index)
                        return nil
                    }
                    return ColumnName(value: name)
                })
            } else {
                items = items.enumerated().compactMap { (index, item) in
                    if ignoredIndexes.contains(index) {
                        return nil
                    }
                    let str: String
                    if let maxLength = maxLength, item.count > maxLength {
                        print("Too long value: \(item), it is shortened.")
                        str = String(item.prefix(6)) + "..."
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

    // MARK: TODO
    public static func fromURL(_ url: URL, separator: String = ",") throws -> Csv {
        let data = try Data(contentsOf: url)
        guard let str = String(data: data, encoding: .utf8) else {
            throw Error.invalidDownloadResource(url: url.absoluteString, data: data)
        }
        return .fromString(str)
    }

    // MARK: TODO
    public static func fromFile(_ file: URL, separator: String = ",") throws -> Csv {
        let data = try Data(contentsOf: file)
        guard let str = String(data: data, encoding: .utf8) else {
            throw Error.invalidLocalResource(url: file.absoluteString, data: data)
        }
        return .fromString(str)
    }
}
