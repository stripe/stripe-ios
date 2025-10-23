//
//  String+StripeCore.swift
//  StripeCore
//
//  Created by Mel Ludowise on 9/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension String {
    public func stp_stringByRemovingCharacters(from characterSet: CharacterSet) -> String {
        return String(unicodeScalars.filter { !characterSet.contains($0) })
    }

    public func stp_stringByRemovingEmoji() -> String {
        return filter { !$0.isEmoji }
    }

    public var isSecretKey: Bool {
        return self.hasPrefix("sk_")
    }

    public var nonEmpty: String? {
        stringIfHasContentsElseNil(self)
    }

    @_spi(STP) public var sanitizedKey: String {
        return (!self.hasPrefix("pk_"))
            ? "[REDACTED_LIVE_KEY]" : self
    }
}

// h/t https://medium.com/better-programming/understanding-swift-strings-characters-and-scalars-a4b82f2d8fde
extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else {
            return false
        }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }
    var isCombinedIntoEmoji: Bool {
        unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false
    }
    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}

@_spi(STP) public func stringIfHasContentsElseNil(
    _ string: String?
) ->  // MARK: -
    String?
{
    guard let string = string,
        !string.isEmpty
    else {
        return nil
    }
    return string
}
