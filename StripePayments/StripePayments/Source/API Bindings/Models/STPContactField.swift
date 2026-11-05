//
//  STPContactField.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 10/6/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

///  Contains constants that represent different parts of a users contact/address information.
public class STPContactField: NSObject, RawRepresentable {
    public let rawValue: String

    public required init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    // We use PKContactField values to handle legacy users who apply XCode's compilable-but-incorrect fix-it to change eg STPContactFieldPostalAddress to PKContactFieldPostalAddress.
    /// The contact's full physical address.
    public static let postalAddress: STPContactField = STPContactField(
        rawValue: PKContactField.postalAddress.rawValue
    )
    /// The contact's email address
    public static let emailAddress: STPContactField = STPContactField(
        rawValue: PKContactField.emailAddress.rawValue
    )
    ///  The contact's phone number.
    public static let phoneNumber: STPContactField = STPContactField(
        rawValue: PKContactField.phoneNumber.rawValue
    )
    ///  The contact's name.
    public static let name: STPContactField = STPContactField(
        rawValue: PKContactField.name.rawValue
    )
}
