//
//  Data+Crypto.swift
//  CardScan
//
//  Created by Jaime Park on 10/8/19.
//

import Foundation
import CommonCrypto

//https://github.com/soffes/Crypto/blob/master/Sources/Crypto/Data%2BCrypto.swift
struct Digest {
    static func sha256(bytes: UnsafeRawBufferPointer, length: UInt32) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(bytes.baseAddress, length, &hash)
        return hash
    }
}

extension Data {
    var hex: String {
        return map { String(format: "%02x", $0) }.reduce("", +)
    }

    var sha256: Data {
        return digest(Digest.sha256)
    }

    private func digest(_ function: ((UnsafeRawBufferPointer, UInt32) -> [UInt8])) -> Data {
        var hash: [UInt8] = []
        withUnsafeBytes { hash = function($0, UInt32(count)) }
        return Data(bytes: hash, count: hash.count)
    }

}
