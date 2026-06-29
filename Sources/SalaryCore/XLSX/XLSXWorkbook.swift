import Foundation

/// One parsed worksheet row: its 1-based spreadsheet row number and the cell text by column
/// (index 0 == column A). Missing cells are empty strings.
public struct XLSXRow: Sendable, Equatable {
    public let number: Int
    public let cells: [String]

    public init(number: Int, cells: [String]) {
        self.number = number
        self.cells = cells
    }

    /// Trimmed value at a column index, or "" if absent.
    public func cell(_ index: Int) -> String {
        guard index >= 0, index < cells.count else { return "" }
        return cells[index].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum XLSXError: Error, Sendable {
    case noWorksheet
}

/// Reads the first worksheet of an `.xlsx` workbook into rows, resolving shared strings.
public struct XLSXWorkbook: Sendable {
    /// All rows including the header (row 1).
    public let rows: [XLSXRow]

    public init(data: Data) throws {
        let zip = try ZipArchiveReader(data: data)

        let sharedStrings: [String]
        if zip.names.contains("xl/sharedStrings.xml") {
            sharedStrings = SharedStringsParser.parse(try zip.data(named: "xl/sharedStrings.xml"))
        } else {
            sharedStrings = []
        }

        let sheetName =
            zip.names
            .filter { $0.hasPrefix("xl/worksheets/sheet") && $0.hasSuffix(".xml") }
            .sorted()
            .first
        guard let sheetName else { throw XLSXError.noWorksheet }

        self.rows = SheetParser.parse(try zip.data(named: sheetName), sharedStrings: sharedStrings)
    }

    /// Data rows (everything after the header row).
    public var dataRows: [XLSXRow] { rows.count > 1 ? Array(rows.dropFirst()) : [] }
}

// MARK: - sharedStrings.xml

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    private var strings: [String] = []
    private var current = ""
    private var inText = false

    static func parse(_ data: Data) -> [String] {
        let parser = XMLParser(data: data)
        let delegate = SharedStringsParser()
        parser.delegate = delegate
        parser.parse()
        return delegate.strings
    }

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String]
    ) {
        if elementName == "si" { current = "" } else if elementName == "t" { inText = true }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inText { current += string }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "t" {
            inText = false
        } else if elementName == "si" {
            strings.append(current)
        }
    }
}

// MARK: - sheetN.xml

private final class SheetParser: NSObject, XMLParserDelegate {
    private let sharedStrings: [String]
    private var rows: [XLSXRow] = []

    private var rowNumber = 0
    private var cellsByColumn: [Int: String] = [:]
    private var maxColumn = -1

    private var cellType = ""
    private var value = ""
    private var capturing = false

    private init(sharedStrings: [String]) { self.sharedStrings = sharedStrings }

    static func parse(_ data: Data, sharedStrings: [String]) -> [XLSXRow] {
        let parser = XMLParser(data: data)
        let delegate = SheetParser(sharedStrings: sharedStrings)
        parser.delegate = delegate
        parser.parse()
        return delegate.rows
    }

    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String: String]
    ) {
        switch elementName {
        case "row":
            rowNumber = attributeDict["r"].flatMap(Int.init) ?? (rowNumber + 1)
            cellsByColumn = [:]
            maxColumn = -1
        case "c":
            cellType = attributeDict["t"] ?? ""
            currentColumn = xlsxColumnIndex(attributeDict["r"] ?? "")
            value = ""
        case "v", "t":
            capturing = true
            value = ""
        default:
            break
        }
    }

    private var currentColumn = 0

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if capturing { value += string }
    }

    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "v", "t":
            capturing = false
        case "c":
            let text: String
            if cellType == "s", let index = Int(value), index >= 0, index < sharedStrings.count {
                text = sharedStrings[index]
            } else {
                text = value
            }
            cellsByColumn[currentColumn] = text
            maxColumn = max(maxColumn, currentColumn)
        case "row":
            var cells = [String](repeating: "", count: max(0, maxColumn + 1))
            for (column, text) in cellsByColumn { cells[column] = text }
            rows.append(XLSXRow(number: rowNumber, cells: cells))
        default:
            break
        }
    }

}

/// Converts a cell reference like "AB12" to a 0-based column index ("A" -> 0).
func xlsxColumnIndex(_ reference: String) -> Int {
    var column = 0
    for character in reference {
        guard let ascii = character.asciiValue else { break }
        if ascii >= 65, ascii <= 90 {
            column = column * 26 + Int(ascii - 64)
        } else {
            break
        }
    }
    return column - 1
}
