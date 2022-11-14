//
//  NSCharacterSet+StripeCore.swift
//  StripeCore
//
//  Created by Brian Dorfman on 6/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) extension CharacterSet {
    public static let stp_asciiDigit = CharacterSet(charactersIn: "0123456789")
    public static let stp_asciiLetters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    )
    public static let stp_invertedAsciiDigit = stp_asciiDigit.inverted
    public static let stp_postalCode = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- "
    )
    public static let stp_invertedPostalCode = stp_postalCode.inverted
}
