//
//  STPBankAccount.swift
//  StripePayments
//
//  Created by Charles Scalesse on 10/1/14.
//  Copyright © 2014 Stripe, Inc. All rights reserved.
//

import Foundation

/// Possible validation states for a bank account.
@objc public enum STPBankAccountStatus: Int {
    /// The account has had no activity or validation performed
    case new
    /// Stripe has determined this bank account exists.
    case validated
    /// Bank account verification has succeeded.
    case verified
    /// Verification for this bank account has failed.
    case verificationFailed
    /// A transfer sent to this bank account has failed.
    case errored
}

/// Representation of a user's bank account details that have been tokenized with
/// the Stripe API.
/// - seealso: https://stripe.com/docs/api#bank_accounts
public class STPBankAccount: NSObject, STPAPIResponseDecodable, STPSourceProtocol {
    /// You cannot directly instantiate an `STPBankAccount`. You should only use one
    /// that has been returned from an `STPAPIClient` callback.
    required override init() {
    }

    /// The routing number for the bank account. This should be the ACH routing number,
    /// not the wire routing number.
    @objc public private(set) var routingNumber: String?
    /// Two-letter ISO code representing the country the bank account is located in.
    @objc public private(set) var country: String?
    /// The default currency for the bank account.
    @objc public private(set) var currency: String?
    /// The last 4 digits of the account number.
    @objc public private(set) var last4: String?
    /// The name of the bank that owns the account.
    @objc public private(set) var bankName: String?
    /// The name of the person or business that owns the bank account.
    @objc public private(set) var accountHolderName: String?
    /// The type of entity that holds the account.
    @objc public private(set) var accountHolderType: STPBankAccountHolderType = .individual
    /// A proxy for the account number, this uniquely identifies the account and can be
    /// used to compare equality of different bank accounts.
    @objc public private(set) var fingerprint: String?
    /// The validation status of the bank account. - seealso: STPBankAccountStatus
    @objc public private(set) var status: STPBankAccountStatus = .new

    // MARK: - Deprecated methods

    /// A set of key/value pairs associated with the bank account object.
    /// @deprecated Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead.
    /// - seealso: https://stripe.com/docs/api#metadata
    @available(
        *,
        deprecated,
        message:
            "Metadata is no longer returned to clients using publishable keys. Retrieve them on your server using yoursecret key instead."
    )
    private(set) var metadata: [String: String]?
    /// The Stripe ID for the bank account.
    @available(
        *,
        deprecated,
        message: "Use stripeID (defined in STPSourceProtocol)"
    )
    @objc public var bankAccountId: String? {
        return stripeID
    }
    @objc public private(set) var stripeID: String = ""
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPBankAccountStatus
    class func stringToStatusMapping() -> [String: NSNumber] {
        return [
            "new": NSNumber(value: STPBankAccountStatus.new.rawValue),
            "validated": NSNumber(value: STPBankAccountStatus.validated.rawValue),
            "verified": NSNumber(value: STPBankAccountStatus.verified.rawValue),
            "verification_failed": NSNumber(
                value: STPBankAccountStatus.verificationFailed.rawValue
            ),
            "errored": NSNumber(value: STPBankAccountStatus.errored.rawValue),
        ]
    }

    @objc(statusFromString:) class func status(from string: String) -> STPBankAccountStatus {
        let key = string.lowercased()
        let statusNumber = self.stringToStatusMapping()[key]

        if let statusNumber = statusNumber {
            return (STPBankAccountStatus(rawValue: statusNumber.intValue))!
        }

        return .new
    }

    @objc(stringFromStatus:) class func string(from status: STPBankAccountStatus) -> String? {
        return
            (self.stringToStatusMapping() as NSDictionary).allKeys(
                for: NSNumber(value: status.rawValue)
            )
            .first as? String
    }

    // MARK: - Equality
    /// :nodoc:
    @objc
    public override func isEqual(_ bankAccount: Any?) -> Bool {
        return isEqual(to: bankAccount as? STPBankAccount)
    }

    /// :nodoc:
    @objc public override var hash: Int {
        return stripeID.hash
    }

    func isEqual(to bankAccount: STPBankAccount?) -> Bool {
        guard let bankAccount = bankAccount else {
            return false
        }

        return stripeID == bankAccount.stripeID
    }

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPBankAccount.self), self),
            // Identifier
            "stripeID = \(stripeID)",
            // Basic account details
            "routingNumber = \(routingNumber ?? "")",
            "last4 = \(last4 ?? "")",
            // Additional account details (alphabetical)
            "bankName = \(bankName ?? "")",
            "country = \(country ?? "")",
            "currency = \(currency ?? "")",
            "fingerprint = \(fingerprint ?? "")",
            "status = \(STPBankAccount.string(from: status) ?? "")",
            // Owner details
            "accountHolderName = \(((accountHolderName) != nil ? "<redacted>" : nil) ?? "")",
            "accountHolderType = \(STPBankAccountParams.string(from: accountHolderType))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        // required fields
        guard let stripeId = dict.stp_string(forKey: "id"),
            let last4 = dict.stp_string(forKey: "last4"),
            let bankName = dict.stp_string(forKey: "bank_name"),
            let country = dict.stp_string(forKey: "country"),
            let currency = dict.stp_string(forKey: "currency"),
            let rawStatus = dict.stp_string(forKey: "status")
        else {
            return nil
        }

        let bankAccount = self.init()

        // Identifier
        bankAccount.stripeID = stripeId

        // Basic account details
        bankAccount.routingNumber = dict.stp_string(forKey: "routing_number")
        bankAccount.last4 = last4

        // Additional account details (alphabetical)
        bankAccount.bankName = bankName
        bankAccount.country = country
        bankAccount.currency = currency
        bankAccount.fingerprint = dict.stp_string(forKey: "fingerprint")
        bankAccount.status = self.status(from: rawStatus)

        // Owner details
        bankAccount.accountHolderName = dict.stp_string(forKey: "account_holder_name")
        let rawAccountHolderType = dict.stp_string(forKey: "account_holder_type")
        bankAccount.accountHolderType = STPBankAccountParams.accountHolderType(
            from: rawAccountHolderType ?? ""
        )

        bankAccount.allResponseFields = dict

        return bankAccount
    }
}
