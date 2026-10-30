//
//  STPConnectAccountCompanyParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information about the company or business to use with `STPConnectAccountParams`.
/// - seealso: https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
public class STPConnectAccountCompanyParams: NSObject {

    /// The company’s primary address.
    public var address: STPConnectAccountAddress?

    /// The Kana variation of the company’s primary address (Japan only).
    public var kanaAddress: STPConnectAccountAddress?

    /// The Kanji variation of the company’s primary address (Japan only).
    public var kanjiAddress: STPConnectAccountAddress?

    /// Whether the company’s directors have been provided.
    /// Set this Boolean to true after creating all the company’s directors with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.director requirement.
    /// This value is not automatically set to true after creating directors, so it needs to be updated to indicate all directors have been provided.
    public var directorsProvided: Bool?

    /// The company’s legal name.
    public var name: String?

    /// The Kana variation of the company’s legal name (Japan only).
    public var kanaName: String?

    /// The Kanji variation of the company’s legal name (Japan only).
    public var kanjiName: String?

    /// Whether the company’s owners have been provided.
    /// Set this Boolean to true after creating all the company’s owners with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.owner requirement.
    public var ownersProvided: Bool?

    /// The company’s phone number (used for verification).
    public var phone: String?

    /// The business ID number of the company, as appropriate for the company’s country.
    /// (Examples are an Employer ID Number in the U.S., a Business Number in Canada, or a Company Number in the UK.)
    public var taxID: String?

    /// The jurisdiction in which the taxID is registered (Germany-based companies only).
    public var taxIDRegistrar: String?

    /// The VAT number of the company.
    public var vatID: String?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConnectAccountCompanyParams.self), self),
            // Properties omitted b/c they're PII
            "address: <redacted>",
            "kanaAddress: \((kanaAddress != nil ? "<redacted>" : nil) ?? "")",
            "kanjiAddress: \((kanjiAddress != nil ? "<redacted>" : nil) ?? "")",
            "directorsProvided: \(String(describing: directorsProvided))",
            "name: \(name != nil ? "<redacted>" : "")",
            "kanaName: \(kanaName != nil ? "<redacted>" : "")",
            "kanjiName: \(kanjiName != nil ? "<redacted>" : "")",
            "ownersProvided: \(String(describing: ownersProvided))",
            "phone: \(phone != nil ? "<redacted>" : "")",
            "taxID: \(taxID != nil ? "<redacted>" : "")",
            "taxIDRegistrar: \(taxIDRegistrar != nil ? "<redacted>" : "")",
            "vatID: \(vatID != nil ? "<redacted>" : "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

}

// MARK: - STPFormEncodable
extension STPConnectAccountCompanyParams: STPFormEncodable {
    private var directorsProvided_apiValue: NSNumber? { directorsProvided.map { NSNumber(value: $0) } }
    private var ownersProvided_apiValue: NSNumber? { ownersProvided.map { NSNumber(value: $0) } }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConnectAccountCompanyParams.address: "address",
            \STPConnectAccountCompanyParams.kanaAddress: "address_kana",
            \STPConnectAccountCompanyParams.kanjiAddress: "address_kanji",
            \STPConnectAccountCompanyParams.directorsProvided_apiValue: "directors_provided",
            \STPConnectAccountCompanyParams.name: "name",
            \STPConnectAccountCompanyParams.kanaName: "name_kana",
            \STPConnectAccountCompanyParams.kanjiName: "name_kanji",
            \STPConnectAccountCompanyParams.ownersProvided_apiValue: "owners_provided",
            \STPConnectAccountCompanyParams.phone: "phone",
            \STPConnectAccountCompanyParams.taxID: "tax_id",
            \STPConnectAccountCompanyParams.taxIDRegistrar: "tax_id_registrar",
            \STPConnectAccountCompanyParams.vatID: "vat_id",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }
}
