import Foundation
import SwiftSyntax
import SwiftParser
import Csv2Img

public struct CsvCompositionParser {

    public enum Error: LocalizedError {
        case fileNotFound(
            type: String
        )
        case failedToDecodeWithUtf8
    }
    
    public static func parse<Composition: CsvComposition>(
        type: Composition.Type,
        rows: [Csv.Row] = []
    ) throws -> Csv {
        let compositionType = String(
            describing: type
        )
        guard let file = Bundle.main.url(
            forResource: compositionType,
            withExtension: "txt"
        ) else {
            throw Error.fileNotFound(
                type: compositionType
            )
        }
        let content = try Data(
            contentsOf: file
        )
        guard let source = String(
            data: content,
            encoding: .utf8
        ) else {
            throw Error.failedToDecodeWithUtf8
        }
        let syntax: SourceFileSyntax = Parser.parse(
            source: source
        )
        return parseIntoCsv(
            type: type,
            source: syntax,
            rows: rows
        )
    }
    
    static func parseIntoCsv<C: CsvComposition>(
        type: C.Type,
        source: SourceFileSyntax,
        rows: [Csv.Row] = []
    ) -> Csv {
        var allColumns: [Csv.Column] = []
        for statement in source.statements {
            // Find struct which conforms to CsvComposition
            switch statement.item {
            case .decl(
                let decl
            ):
                guard let decl = decl.as(
                    StructDeclSyntax.self
                ) else {
                    break
                }
                if !validateInheritedType(
                    decl: decl
                ) {
                    break
                }
                let members = decl.memberBlock.members
                let columns = decl.findColumns(
                    type: C.self,
                    members: members
                )
                    .map {
                        Csv.Column.init(
                            name: $0,
                            style: .random()
                        )
                    }
                allColumns.append(
                    contentsOf: columns
                )
            default:
                break
            }
        }
        return Csv(
            separator: ",",
            columns: allColumns,
            rows: rows,
            exportType: .pdf
        )
    }
    
    static func validateInheritedType(
        decl: StructDeclSyntax
    ) -> Bool {
        decl.inheritanceClause?
            .inheritedTypes
            .map(
                \.type
            )
            .compactMap { syntax in
                syntax.as(
                    IdentifierTypeSyntax.self
                )
            }
            .first(where: {
                syntax in
                syntax.name.description.contains(
                    "CsvComposition"
                )
            }) != nil
    }
    
    static func extractColumns<C: CsvComposition>(
        _ type: C.Type,
        variableDecl decl: VariableDeclSyntax
    ) -> [String] {
        let attributes = decl.attributes
        return attributes.compactMap { attribute in
            var columns: [String] = []
            for attr in attributes {
                guard let attr = attr.as(
                    AttributeSyntax.self
                ) else {
                    continue
                }
                let hasCsvRowsAttr = attr.attributeName.as(
                    IdentifierTypeSyntax.self
                )?.name.text == "CsvRows"
                if !hasCsvRowsAttr {
                    continue
                }
                guard let tokens = attr.arguments?.tokens(
                    viewMode: .all
                ) else {
                    continue
                }
                let column = tokens
                    .compactMap {
                        if case let TokenKind.stringSegment(
                            column
                        ) = $0.tokenKind {
                            return column
                        }
                        return nil
                    }
                    .first
                guard let column else {
                    continue
                }
                columns.append(
                    column
                )
            }
            return columns
        }
        .flatMap {
            $0
        }
    }
}

extension StructDeclSyntax {
    func findColumns(
        type: (
            some CsvComposition
        ).Type,
        members: MemberBlockItemListSyntax
    ) -> [String] {
        var columns: [String] = []
        for member in members {
            guard let decl = member.decl.as(
                VariableDeclSyntax.self
            ) else {
                continue
            }
            let c = CsvCompositionParser.extractColumns(
                type,
                variableDecl: decl
            )
            if c.isEmpty {
                continue
            }
            columns.append(
                contentsOf: c
            )
        }
        return columns
    }
}
