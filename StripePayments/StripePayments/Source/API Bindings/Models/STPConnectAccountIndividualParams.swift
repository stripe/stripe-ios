//
//  STPConnectAccountIndividualParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information about the person represented by the account for use with `STPConnectAccountParams`.
/// - seealso: https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual
public class STPConnectAccountIndividualParams: NSObject {

    /// The individual’s primary address.
    public var address: STPConnectAccountAddress?

    /// The Kana variation of the the individual’s primary address (Japan only).
    public var kanaAddress: STPConnectAccountAddress?

    /// The Kanji variation of the the individual’s primary address (Japan only).
    public var kanjiAddress: STPConnectAccountAddress?

    /// The individual’s date of birth.
    /// Must include `day`, `month`, and `year`, and only those fields are used.
    public var dateOfBirth: DateComponents?

    /// The individual's email address.
    public var email: String?

    /// The individual’s first name.
    public var firstName: String?

    /// The Kana variation of the the individual’s first name (Japan only).
    public var kanaFirstName: String?

    /// The Kanji variation of the individual’s first name (Japan only).
    public var kanjiFirstName: String?

    /// The individual’s gender
    /// International regulations require either “male” or “female”.
    public var gender: String?

    /// The government-issued ID number of the individual, as appropriate for the representative’s country.
    /// Examples are a Social Security Number in the U.S., or a Social Insurance Number in Canada.
    /// Instead of the number itself, you can also provide a PII token (see https://stripe.com/docs/api/tokens/create_pii).
    public var idNumber: String?

    /// The individual’s last name.
    public var lastName: String?

    /// The Kana varation of the individual’s last name (Japan only).
    public var kanaLastName: String?

    /// The Kanji varation of the individual’s last name (Japan only).
    public var kanjiLastName: String?

    /// The individual’s maiden name.
    public var maidenName: String?

    /// Set of key-value pairs that you can attach to an object.
    /// This can be useful for storing additional information about the object in a structured format.
    public var metadata: [AnyHashable: Any]?

    /// The individual’s phone number.
    public var phone: String?

    /// The last four digits of the individual’s Social Security Number (U.S. only).
    public var ssnLast4: String?

    /// The individual’s verification document information.
    public var verification: STPConnectAccountIndividualVerification?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPConnectAccountIndividualParams.self),
                self
            ),
            // Properties
            "address = \(address != nil ? "<redacted>" : "")",
            "kanaAddress = \(kanaAddress != nil ? "<redacted>" : "")",
            "kanjiAddress = \(kanjiAddress != nil ? "<redacted>" : "")",
            "dateOfBirth = \(dateOfBirth != nil ? "<redacted>" : "")",
            "email = \(email != nil ? "<redacted>" : "")",
            "firstName = \(firstName != nil ? "<redacted>" : "")",
            "kanaFirstName = \(kanaFirstName != nil ? "<redacted>" : "")",
            "kanjiFirstName = \(kanjiFirstName != nil ? "<redacted>" : "")",
            "gender = \(gender != nil ? "<redacted>" : "")",
            "idNumber = \(idNumber != nil ? "<redacted>" : "")",
            "lastName = \(lastName != nil ? "<redacted>" : "")",
            "kanaLastName = \(kanaLastName != nil ? "<redacted>" : "")",
            "kanjiLastNaame = \(kanjiLastName != nil ? "<redacted>" : "")",
            "maidenName = \(maidenName != nil ? "<redacted>" : "")",
            "metadata = \(metadata != nil ? "<redacted>" : "")",
            "phone = \(phone != nil ? "<redacted>" : "")",
            "ssnLast4 = \(ssnLast4 != nil ? "<redacted>" : "")",
            "verification = \(String(describing: verification))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    var _dateOfBirth: STPDateOfBirth? {
        guard let dateOfBirth = dateOfBirth else {
            return nil
        }

        let dob = STPDateOfBirth()
        dob.day = dateOfBirth.day ?? 0
        dob.month = dateOfBirth.month ?? 0
        dob.year = dateOfBirth.year ?? 0
        return dob
    }
}

extension STPConnectAccountIndividualParams: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConnectAccountIndividualParams.address: "address",
            \STPConnectAccountIndividualParams.kanaAddress: "address_kana",
            \STPConnectAccountIndividualParams.kanjiAddress: "address_kanji",
            \STPConnectAccountIndividualParams._dateOfBirth: "dob",
            \STPConnectAccountIndividualParams.email: "email",
            \STPConnectAccountIndividualParams.firstName: "first_name",
            \STPConnectAccountIndividualParams.kanaFirstName: "first_name_kana",
            \STPConnectAccountIndividualParams.kanjiFirstName: "first_name_kanji",
            \STPConnectAccountIndividualParams.gender: "gender",
            \STPConnectAccountIndividualParams.idNumber: "id_number",
            \STPConnectAccountIndividualParams.lastName: "last_name",
            \STPConnectAccountIndividualParams.kanaLastName: "last_name_kana",
            \STPConnectAccountIndividualParams.kanjiLastName: "last_name_kanji",
            \STPConnectAccountIndividualParams.maidenName: "maiden_name",
            \STPConnectAccountIndividualParams.metadata: "metadata",
            \STPConnectAccountIndividualParams.phone: "phone",
            \STPConnectAccountIndividualParams.ssnLast4: "ssn_last_4",
            \STPConnectAccountIndividualParams.verification: "verification",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: -

/// The individual’s verification document information for use with `STPConnectAccountIndividualParams`.
public class STPConnectAccountIndividualVerification: NSObject {

    /// An identifying document, either a passport or local ID card.
    public var document: STPConnectAccountVerificationDocument?

    /// A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
    public var additionalDocument: STPConnectAccountVerificationDocument?

    public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPConnectAccountIndividualVerification: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConnectAccountIndividualVerification.document: "document",
            \STPConnectAccountIndividualVerification.additionalDocument: "additional_document",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: -

/// An identifying document, either a passport or local ID card for use with `STPConnectAccountIndividualVerification`.
public class STPConnectAccountVerificationDocument: NSObject {

    /// The back of an ID returned by a file upload with a `purpose` value of `identity_document`.
    /// - seealso: https://stripe.com/docs/api/files/create for file uploads
    public var back: String?

    /// The front of an ID returned by a file upload with a `purpose` value of `identity_document`.
    /// - seealso: https://stripe.com/docs/api/files/create for file uploads
    public var front: String?

    public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPConnectAccountVerificationDocument: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConnectAccountVerificationDocument.back: "back",
            \STPConnectAccountVerificationDocument.front: "front",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: - Date of Birth

/// An individual's date of birth.
/// See https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual-dob
public class STPDateOfBirth: NSObject {

    /// The day of birth, between 1 and 31.
    public var day = 0

    /// The month of birth, between 1 and 12.
    public var month = 0

    /// The four-digit year of birth.
    public var year = 0

    public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPDateOfBirth: STPFormEncodable {
    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPDateOfBirth.day: "day",
            \STPDateOfBirth.month: "month",
            \STPDateOfBirth.year: "year",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}
