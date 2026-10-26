//
//  String+UnicodeScalarPrefix.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/6/26.
//

extension String {

    /// Returns the longest prefix with at most `maximumCount` Unicode scalars, without splitting a character.
    ///
    /// - Parameter maximumCount: The maximum number of Unicode scalars to include. A negative value returns an empty prefix.
    func prefix(unicodeScalarsCount maximumCount: Int) -> Substring {
        guard maximumCount >= 0 else { return "" }
        guard unicodeScalars.count > maximumCount else { return self[...] }

        var remainingLength = maximumCount
        return prefix { character in
            let length = character.unicodeScalars.count
            guard length <= remainingLength else { return false }
            remainingLength -= length
            return true
        }
    }
}
