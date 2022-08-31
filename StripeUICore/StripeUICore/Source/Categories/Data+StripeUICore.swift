//
//  Data+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation
import Compression

extension Data {
    /// An error that occurs when loading an LZFSE compressed file fails.
    enum LZFSEDecompressionError: Error {
        /// No enough data for decompressing.
        case noEnoughData
        /// Decompressing the payload didn't produce the expected size. An indication that the file is truncated.
        case fileIsTruncated
    }

    /// Loads LZFSE compressed files.
    ///
    /// This method throws `LZFSEDecompressionError` if the file cannot be decompressed.
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

        return try compressedData.withUnsafeBytes { pointer in
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

            guard decompressedByteCount == expectedSize else {
                assertionFailure("LZFSE file is truncated")
                throw LZFSEDecompressionError.fileIsTruncated
            }

            return Data(bytes: destinationBuffer, count: decompressedByteCount)
        }
    }
}
