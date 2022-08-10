//
//  Data+StripeUICore.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation
import Compression

// TODO(ramont): Move to StripeCore

extension Data {
    enum DecompressionError: Error {
        case notEnoughData
    }

    static func fromLZFSEFile(at url: URL) throws -> Data {
        let allData = try Data(contentsOf: url)

        guard allData.count > 8 else {
            throw DecompressionError.notEnoughData
        }

        let expectedSize = Int(
            allData[0...8].withUnsafeBytes { $0.load(as: UInt64.self) }
        )

        let compressedData = allData[8...]

        return compressedData.withUnsafeBytes { pointer in
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)

            let decompressedByteCount = compression_decode_buffer(
                buffer,
                expectedSize,
                pointer.baseAddress!,
                compressedData.count,
                nil,
                COMPRESSION_LZFSE
            )

            assert(decompressedByteCount == expectedSize)

            return Data(bytes: buffer, count: decompressedByteCount)
        }
    }
}
