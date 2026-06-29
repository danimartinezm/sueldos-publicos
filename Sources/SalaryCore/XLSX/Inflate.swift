import Compression
import Foundation

enum InflateError: Error, Sendable {
    case decodeFailed
}

/// Raw DEFLATE (RFC 1951) decompression using Apple's Compression framework.
///
/// ZIP entries store raw DEFLATE streams (no zlib header/trailer), which is exactly what
/// `COMPRESSION_ZLIB` consumes. Using the platform framework keeps the XLSX reader free of any
/// third-party dependency (Constitution: Custom-First / Minimal Dependencies).
enum Inflate {
    static func rawDeflate(_ data: Data, expectedSize: Int) throws -> Data {
        if expectedSize == 0 { return Data() }
        var output = Data(count: expectedSize)
        let written = output.withUnsafeMutableBytes { (dst: UnsafeMutableRawBufferPointer) -> Int in
            data.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Int in
                guard
                    let dstBase = dst.bindMemory(to: UInt8.self).baseAddress,
                    let srcBase = src.bindMemory(to: UInt8.self).baseAddress
                else { return 0 }
                return compression_decode_buffer(
                    dstBase, expectedSize,
                    srcBase, src.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard written == expectedSize else { throw InflateError.decodeFailed }
        return output
    }
}
