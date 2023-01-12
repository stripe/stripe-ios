//
//  Data+SHA256.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 2/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import CommonCrypto
import Foundation

// Adapted from https://stackoverflow.com/questions/25388747/sha256-in-swift
extension Data {

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
