import Foundation

enum ZipError: Error, Sendable, Equatable {
    case notZip
    case eocdNotFound
    case badCentralHeader
    case badLocalHeader
    case entryNotFound(String)
    case unsupportedCompression(UInt16)
}

/// Minimal read-only ZIP container reader.
///
/// Parses the End-Of-Central-Directory record and central directory to locate entries, then
/// inflates each requested entry on demand. Only the subset of ZIP needed for `.xlsx`
/// (stored + DEFLATE, no ZIP64) is supported — deliberately small per Custom-First.
struct ZipArchiveReader {
    private struct Entry {
        let compressionMethod: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    private let data: Data
    private let entries: [String: Entry]

    /// All entry names contained in the archive.
    var names: [String] { Array(entries.keys) }

    init(data: Data) throws {
        // Re-base into a 0-indexed buffer so all offsets are absolute and simple.
        self.data = Data(data)
        self.entries = try Self.readCentralDirectory(self.data)
    }

    /// Returns the decompressed bytes for the named entry.
    func data(named name: String) throws -> Data {
        guard let entry = entries[name] else { throw ZipError.entryNotFound(name) }
        let base = entry.localHeaderOffset
        guard base + 30 <= data.count, data.le32(base) == 0x0403_4b50 else {
            throw ZipError.badLocalHeader
        }
        let nameLen = Int(data.le16(base + 26))
        let extraLen = Int(data.le16(base + 28))
        let dataStart = base + 30 + nameLen + extraLen
        guard dataStart + entry.compressedSize <= data.count else { throw ZipError.badLocalHeader }
        let compressed = data.subdata(in: dataStart..<dataStart + entry.compressedSize)
        switch entry.compressionMethod {
        case 0: return compressed
        case 8: return try Inflate.rawDeflate(compressed, expectedSize: entry.uncompressedSize)
        default: throw ZipError.unsupportedCompression(entry.compressionMethod)
        }
    }

    private static func readCentralDirectory(_ data: Data) throws -> [String: Entry] {
        let count = data.count
        guard count >= 22 else { throw ZipError.notZip }

        // Locate the End Of Central Directory record by scanning backward for its signature.
        var eocd = -1
        let minStart = max(0, count - 22 - 0xFFFF)
        var i = count - 22
        while i >= minStart {
            if data.le32(i) == 0x0605_4b50 { eocd = i; break }
            i -= 1
        }
        guard eocd >= 0 else { throw ZipError.eocdNotFound }

        let cdCount = Int(data.le16(eocd + 10))
        let cdOffset = Int(data.le32(eocd + 16))

        var entries: [String: Entry] = [:]
        var p = cdOffset
        for _ in 0..<cdCount {
            guard p + 46 <= count, data.le32(p) == 0x0201_4b50 else {
                throw ZipError.badCentralHeader
            }
            let method = data.le16(p + 10)
            let compSize = Int(data.le32(p + 20))
            let uncompSize = Int(data.le32(p + 24))
            let nameLen = Int(data.le16(p + 28))
            let extraLen = Int(data.le16(p + 30))
            let commentLen = Int(data.le16(p + 32))
            let localOffset = Int(data.le32(p + 42))
            let nameData = data.subdata(in: p + 46..<p + 46 + nameLen)
            let name = String(decoding: nameData, as: UTF8.self)
            entries[name] = Entry(
                compressionMethod: method,
                compressedSize: compSize,
                uncompressedSize: uncompSize,
                localHeaderOffset: localOffset
            )
            p += 46 + nameLen + extraLen + commentLen
        }
        return entries
    }
}

extension Data {
    /// Little-endian 16-bit read at a 0-based offset.
    func le16(_ offset: Int) -> UInt16 {
        let b = startIndex + offset
        return UInt16(self[b]) | (UInt16(self[b + 1]) << 8)
    }

    /// Little-endian 32-bit read at a 0-based offset.
    func le32(_ offset: Int) -> UInt32 {
        let b = startIndex + offset
        return UInt32(self[b])
            | (UInt32(self[b + 1]) << 8)
            | (UInt32(self[b + 2]) << 16)
            | (UInt32(self[b + 3]) << 24)
    }
}
