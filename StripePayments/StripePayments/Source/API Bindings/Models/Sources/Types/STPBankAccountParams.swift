//
//  STPBankAccountParams.swift
//  StripePayments
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

import Foundation

/// The type of entity that holds a bank account.
public enum STPBankAccountHolderType: Int {
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
    public var accountNumber: String?
    /// The last 4 digits of the bank account's account number, if it's been set,
    /// otherwise nil.

    public var last4: String? {
        if accountNumber != nil && (accountNumber?.count ?? 0) >= 4 {
            return (accountNumber as NSString?)?.substring(from: (accountNumber?.count ?? 0) - 4)
                ?? ""
        } else {
            return nil
        }
    }
    /// The routing number for the bank account. This should be the ACH routing number,
    /// not the wire routing number.
    public var routingNumber: String?
    /// Two-letter ISO code representing the country the bank account is located in.
    public var country: String?
    /// The default currency for the bank account.
    public var currency: String?
    /// The name of the person or business that owns the bank account.
    public var accountHolderName: String?
    /// The type of entity that holds the account.
    /// Defaults to STPBankAccountHolderTypeIndividual.
    public var accountHolderType: STPBankAccountHolderType = .individual

    public var additionalAPIParameters: [AnyHashable: Any] = [:]

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

    class func accountHolderType(
        from string: String
    )
        -> STPBankAccountHolderType
    {
        let key = string.lowercased()
        return self.stringToAccountHolderTypeMapping[key] ?? .individual
    }

    class func string(
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
    public override var description: String {
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
    public class func rootObjectName() -> String? {
        return "bank_account"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPBankAccountParams.accountNumber: "account_number",
            \STPBankAccountParams.routingNumber: "routing_number",
            \STPBankAccountParams.country: "country",
            \STPBankAccountParams.currency: "currency",
            \STPBankAccountParams.accountHolderName: "account_holder_name",
            \STPBankAccountParams.accountHolderTypeString: "account_holder_type",
        ]
    }

    var accountHolderTypeString: String {
        return STPBankAccountParams.string(from: accountHolderType)
    }
}
