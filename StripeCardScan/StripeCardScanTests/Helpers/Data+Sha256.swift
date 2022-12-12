//
//  Data+Sha256.swift
//  StripeCardScanTests
//
//  Created by Scott Grant on 9/21/22.
//

import CommonCrypto
import Foundation

// Adapted from https://stackoverflow.com/questions/25388747/sha256-in-swift
extension Data {

    /// A String containing the Sha256 hash of this Data's contents.
    var sha256: String {
        return digest().base64EncodedString()
    }

    private func digest() -> Data {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256([UInt8](self), UInt32(self.count), &hash)

        return Data(bytes: hash, count: digestLength)
    }
}
