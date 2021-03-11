//
//  NSCharacterSet+Stripe.swift
//  Stripe
//
//  Created by Brian Dorfman on 6/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

extension CharacterSet {
    static let stp_asciiDigit = CharacterSet(charactersIn: "0123456789")
    static let stp_invertedAsciiDigit = stp_asciiDigit.inverted
    static let stp_postalCode = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- ")
    static let stp_invertedPostalCode = stp_postalCode.inverted
}
