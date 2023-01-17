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
    @objc public var address: STPConnectAccountAddress?

    /// The Kana variation of the the individual’s primary address (Japan only).
    @objc public var kanaAddress: STPConnectAccountAddress?

    /// The Kanji variation of the the individual’s primary address (Japan only).
    @objc public var kanjiAddress: STPConnectAccountAddress?

    /// The individual’s date of birth.
    /// Must include `day`, `month`, and `year`, and only those fields are used.
    @objc public var dateOfBirth: DateComponents?

    /// The individual's email address.
    @objc public var email: String?

    /// The individual’s first name.
    @objc public var firstName: String?

    /// The Kana variation of the the individual’s first name (Japan only).
    @objc public var kanaFirstName: String?

    /// The Kanji variation of the individual’s first name (Japan only).
    @objc public var kanjiFirstName: String?

    /// The individual’s gender
    /// International regulations require either “male” or “female”.
    @objc public var gender: String?

    /// The government-issued ID number of the individual, as appropriate for the representative’s country.
    /// Examples are a Social Security Number in the U.S., or a Social Insurance Number in Canada.
    /// Instead of the number itself, you can also provide a PII token (see https://stripe.com/docs/api/tokens/create_pii).
    @objc public var idNumber: String?

    /// The individual’s last name.
    @objc public var lastName: String?

    /// The Kana varation of the individual’s last name (Japan only).
    @objc public var kanaLastName: String?

    /// The Kanji varation of the individual’s last name (Japan only).
    @objc public var kanjiLastName: String?

    /// The individual’s maiden name.
    @objc public var maidenName: String?

    /// Set of key-value pairs that you can attach to an object.
    /// This can be useful for storing additional information about the object in a structured format.
    @objc public var metadata: [AnyHashable: Any]?

    /// The individual’s phone number.
    @objc public var phone: String?

    /// The last four digits of the individual’s Social Security Number (U.S. only).
    @objc public var ssnLast4: String?

    /// The individual’s verification document information.
    @objc public var verification: STPConnectAccountIndividualVerification?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
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

    @objc var _dateOfBirth: STPDateOfBirth? {
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
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: address)): "address",
            NSStringFromSelector(#selector(getter: kanaAddress)): "address_kana",
            NSStringFromSelector(#selector(getter: kanjiAddress)): "address_kanji",
            NSStringFromSelector(#selector(getter: _dateOfBirth)): "dob",
            NSStringFromSelector(#selector(getter: email)): "email",
            NSStringFromSelector(#selector(getter: firstName)): "first_name",
            NSStringFromSelector(#selector(getter: kanaFirstName)): "first_name_kana",
            NSStringFromSelector(#selector(getter: kanjiFirstName)): "first_name_kanji",
            NSStringFromSelector(#selector(getter: gender)): "gender",
            NSStringFromSelector(#selector(getter: idNumber)): "id_number",
            NSStringFromSelector(#selector(getter: lastName)): "last_name",
            NSStringFromSelector(#selector(getter: kanaLastName)): "last_name_kana",
            NSStringFromSelector(#selector(getter: kanjiLastName)): "last_name_kanji",
            NSStringFromSelector(#selector(getter: maidenName)): "maiden_name",
            NSStringFromSelector(#selector(getter: metadata)): "metadata",
            NSStringFromSelector(#selector(getter: phone)): "phone",
            NSStringFromSelector(#selector(getter: ssnLast4)): "ssn_last_4",
            NSStringFromSelector(#selector(getter: verification)): "verification",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: -

/// The individual’s verification document information for use with `STPConnectAccountIndividualParams`.
public class STPConnectAccountIndividualVerification: NSObject {

    /// An identifying document, either a passport or local ID card.
    @objc public var document: STPConnectAccountVerificationDocument?

    /// A document showing address, either a passport, local ID card, or utility bill from a well-known utility company.
    @objc public var additionalDocument: STPConnectAccountVerificationDocument?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPConnectAccountIndividualVerification: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: document)): "document",
            NSStringFromSelector(#selector(getter: additionalDocument)): "additional_document",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: -

/// An identifying document, either a passport or local ID card for use with `STPConnectAccountIndividualVerification`.
public class STPConnectAccountVerificationDocument: NSObject {

    /// The back of an ID returned by a file upload with a `purpose` value of `identity_document`.
    /// - seealso: https://stripe.com/docs/api/files/create for file uploads
    @objc public var back: String?

    /// The front of an ID returned by a file upload with a `purpose` value of `identity_document`.
    /// - seealso: https://stripe.com/docs/api/files/create for file uploads
    @objc public var front: String?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPConnectAccountVerificationDocument: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: back)): "back",
            NSStringFromSelector(#selector(getter: front)): "front",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
}

// MARK: - Date of Birth

/// An individual's date of birth.
/// See https://stripe.com/docs/api/tokens/create_account#create_account_token-account-individual-dob
public class STPDateOfBirth: NSObject {

    /// The day of birth, between 1 and 31.
    @objc public var day = 0

    /// The month of birth, between 1 and 12.
    @objc public var month = 0

    /// The four-digit year of birth.
    @objc public var year = 0

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

extension STPDateOfBirth: STPFormEncodable {
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: day)): "day",
            NSStringFromSelector(#selector(getter: month)): "month",
            NSStringFromSelector(#selector(getter: year)): "year",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
}
