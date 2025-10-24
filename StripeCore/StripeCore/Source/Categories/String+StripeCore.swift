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

extension Character {
    // Check if each character contains a scalar that has a default emoji presentation
    // or contains the emojification codepoint (U+FE0F, Variation Selector-16)
    // This may miss some combined emoji, but seems safer than `isEmoji` (which filters emoji-able things that people wouldn't normally consider emoji, like digits)
    // I've seen suggestions to use `> 0x238C && isEmoji`, but I'm worried that this may fail if a character
    // above that range gains a default emoji presentation.
    var isEmoji: Bool { unicodeScalars.first(where: { $0.properties.isEmojiPresentation || ($0.value == 0xFE0F) }) != nil }
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
