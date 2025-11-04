//
//  VerifyKYCInfo.swift
//  StripePaymentSheet
//
//  Created by Michael Liberatore on 11/3/25.
//

import Foundation

/// Describes a type that contains all of the necessary information for verifying KYC information.
@_spi(STP) public protocol VerifyKYCInfo {

    /// The user’s first name.
    var firstName: String { get }

    /// The user’s last name.
    var lastName: String? { get }

    /// The user’s birthday day component.
    var dateOfBirthDay: Int { get }

    /// The user’s birthday month component.
    var dateOfBirthMonth: Int { get }

    /// The user’s birthday year component.
    var dateOfBirthYear: Int { get }

    /// City, district, suburb, town, or village.
    var city: String? { get }

    /// Two-letter country code (ISO 3166-1 alpha-2).
    var country: String? { get }

    /// Address line 1 (e.g., street, PO Box, or company name).
    var line1: String? { get }

    /// Address line 2 (e.g., apartment, suite, unit, or building).
    var line2: String? { get }

    /// ZIP or postal code.
    var postalCode: String? { get }

    /// State, county, province, or region.
    var state: String? { get }

    /// The last four digits of the user’s id number.
    var idNumberLast4: String? { get }
}
