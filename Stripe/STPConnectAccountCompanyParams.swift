//
//  STPConnectAccountCompanyParams.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Information about the company or business to use with `STPConnectAccountParams`.
/// - seealso: https://stripe.com/docs/api/tokens/create_account#create_account_token-account-company
public class STPConnectAccountCompanyParams: NSObject {

  /// The company’s primary address.
  @objc public var address: STPConnectAccountAddress?

  /// The Kana variation of the company’s primary address (Japan only).
  @objc public var kanaAddress: STPConnectAccountAddress?

  /// The Kanji variation of the company’s primary address (Japan only).
  @objc public var kanjiAddress: STPConnectAccountAddress?

  /// Whether the company’s directors have been provided.
  /// Set this Boolean to true after creating all the company’s directors with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.director requirement.
  /// This value is not automatically set to true after creating directors, so it needs to be updated to indicate all directors have been provided.
  @objc public var directorsProvided: Bool = false

  /// The company’s legal name.
  @objc public var name: String?

  /// The Kana variation of the company’s legal name (Japan only).
  @objc public var kanaName: String?

  /// The Kanji variation of the company’s legal name (Japan only).
  @objc public var kanjiName: String?

  /// Whether the company’s owners have been provided.
  /// Set this Boolean to true after creating all the company’s owners with the Persons API (https://stripe.com/docs/api/persons) for accounts with a relationship.owner requirement.
  @objc public var ownersProvided: Bool = false

  /// The company’s phone number (used for verification).
  @objc public var phone: String?

  /// The business ID number of the company, as appropriate for the company’s country.
  /// (Examples are an Employer ID Number in the U.S., a Business Number in Canada, or a Company Number in the UK.)
  @objc public var taxID: String?

  /// The jurisdiction in which the taxID is registered (Germany-based companies only).
  @objc public var taxIDRegistrar: String?

  /// The VAT number of the company.
  @objc public var vatID: String?

  /// :nodoc:
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
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
  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:address)): "address",
      NSStringFromSelector(#selector(getter:kanaAddress)): "address_kana",
      NSStringFromSelector(#selector(getter:kanjiAddress)): "address_kanji",
      NSStringFromSelector(#selector(getter:directorsProvided)): "directors_provided",
      NSStringFromSelector(#selector(getter:name)): "name",
      NSStringFromSelector(#selector(getter:kanaName)): "name_kana",
      NSStringFromSelector(#selector(getter:kanjiName)): "name_kanji",
      NSStringFromSelector(#selector(getter:ownersProvided)): "owners_provided",
      NSStringFromSelector(#selector(getter:phone)): "phone",
      NSStringFromSelector(#selector(getter:taxID)): "tax_id",
      NSStringFromSelector(#selector(getter:taxIDRegistrar)): "tax_id_registrar",
      NSStringFromSelector(#selector(getter:vatID)): "vat_id",
    ]
  }

  @objc
  public class func rootObjectName() -> String? {
    return nil
  }
}
