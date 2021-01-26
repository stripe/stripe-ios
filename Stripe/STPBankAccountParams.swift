//
//  STPBankAccountParams.swift
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of entity that holds a bank account.
@objc public enum STPBankAccountHolderType: Int {
  /// An individual holds this bank account.
  case individual
  /// A company holds this bank account.
  case company
}

/// Representation of a user's bank account details. You can assemble these with
/// information that your user enters and then create Stripe tokens with them using
/// an STPAPIClient.
/// - seealso: https://stripe.com/docs/api#create_bank_account_token
public class STPBankAccountParams: NSObject, STPFormEncodable {
  /// The account number for the bank account. Currently must be a checking account.
  @objc public var accountNumber: String?
  /// The last 4 digits of the bank account's account number, if it's been set,
  /// otherwise nil.

  @objc public var last4: String? {
    if accountNumber != nil && (accountNumber?.count ?? 0) >= 4 {
      return (accountNumber as NSString?)?.substring(from: (accountNumber?.count ?? 0) - 4) ?? ""
    } else {
      return nil
    }
  }
  /// The routing number for the bank account. This should be the ACH routing number,
  /// not the wire routing number.
  @objc public var routingNumber: String?
  /// Two-letter ISO code representing the country the bank account is located in.
  @objc public var country: String?
  /// The default currency for the bank account.
  @objc public var currency: String?
  /// The name of the person or business that owns the bank account.
  @objc public var accountHolderName: String?
  /// The type of entity that holds the account.
  /// Defaults to STPBankAccountHolderTypeIndividual.
  @objc public var accountHolderType: STPBankAccountHolderType = .individual

  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// Initializes an empty STPBankAccountParams.
  public override init() {
    super.init()
    additionalAPIParameters = [:]
    accountHolderType = .individual
  }

  // MARK: - STPBankAccountHolderType
  static var stringToAccountHolderTypeMapping: [String: STPBankAccountHolderType] = [
    "individual": .individual,
    "company": .company,
  ]

  @objc(accountHolderTypeFromString:) class func accountHolderType(from string: String)
    -> STPBankAccountHolderType
  {
    let key = string.lowercased()
    return self.stringToAccountHolderTypeMapping[key] ?? .individual
  }

  @objc(stringFromAccountHolderType:) class func string(
    from accountHolderType: STPBankAccountHolderType
  ) -> String {
    guard
      let stringTuple = self.stringToAccountHolderTypeMapping.filter({
        return $0.1 == accountHolderType
      }).first?.0
    else {
      return "individual"
    }
    return stringTuple
  }

  // MARK: - Description
  /// :nodoc:
  @objc public override var description: String {
    let props = [
      // Object
      String(format: "%@: %p", NSStringFromClass(STPBankAccountParams.self), self),
      // Basic account details
      "routingNumber = \(routingNumber ?? "")",
      "last4 = \(last4 ?? "")",
      // Additional account details (alphabetical)
      "country = \(country ?? "")",
      "currency = \(currency ?? "")",
      // Owner details
      "accountHolderName = \(((accountHolderName) != nil ? "<redacted>" : nil) ?? "")",
      "accountHolderType = \(STPBankAccountParams.string(from: accountHolderType))",
    ]

    return "<\(props.joined(separator: "; "))>"
  }

  // MARK: - STPFormEncodable
  @objc
  public class func rootObjectName() -> String? {
    return "bank_account"
  }

  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:accountNumber)): "account_number",
      NSStringFromSelector(#selector(getter:routingNumber)): "routing_number",
      NSStringFromSelector(#selector(getter:country)): "country",
      NSStringFromSelector(#selector(getter:currency)): "currency",
      NSStringFromSelector(#selector(getter:accountHolderName)): "account_holder_name",
      NSStringFromSelector(#selector(accountHolderTypeString)): "account_holder_type",
    ]
  }

  @objc func accountHolderTypeString() -> String {
    return STPBankAccountParams.string(from: accountHolderType)
  }
}
