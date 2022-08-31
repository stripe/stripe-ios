//
//  Data+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation
import Compression

extension Data {
    enum LZFSEDecompressionError: Error {
        case noEnoughData
    }

    /// Loads LZFSE compressed files.
    ///
    /// - Parameter url: The URL from which to read the compressed data.
    /// - Returns: Decompressed data.
    static func fromLZFSEFile(at url: URL) throws -> Data {
        let allData = try Data(contentsOf: url)

        // .lzfse files are structured as follows:
        //
        // +--------------+-----------------------------------------+
        // | 8 bytes      | Uncompressed file size (little endian.) |
        // |--------------|-----------------------------------------|
        // | n-bytes      | LZFSE compressed payload.               |
        // +--------------+-----------------------------------------+

        guard allData.count > 8 else {
            throw LZFSEDecompressionError.noEnoughData
        }

        let expectedSize = Int(
            allData.withUnsafeBytes {
                UInt64(littleEndian: $0.load(fromByteOffset: 0, as: UInt64.self))
            }
        )

        let compressedData = allData[8...]

        return compressedData.withUnsafeBytes { pointer in
            let sourceBuffer = pointer.map { $0 }
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)

            let decompressedByteCount = compression_decode_buffer(
                destinationBuffer,
                expectedSize,
                sourceBuffer,
                compressedData.count,
                nil,
                COMPRESSION_LZFSE
            )

            assert(decompressedByteCount == expectedSize)

            return Data(bytes: destinationBuffer, count: decompressedByteCount)
        }
    }
}
