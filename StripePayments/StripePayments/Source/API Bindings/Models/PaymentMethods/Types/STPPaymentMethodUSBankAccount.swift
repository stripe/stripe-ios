//
//  STPPaymentMethodUSBankAccount.swift
//  StripePayments
//
//  Created by Cameron Sabol on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

// MARK: - STPPaymentMethodUSBankAccount
/// A US Bank Account Payment Method (ACH)
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-us_bank_account
public class STPPaymentMethodUSBankAccount: NSObject {

    /// Account holder type
    @objc public let accountHolderType: STPPaymentMethodUSBankAccountHolderType

    /// Account type
    @objc public let accountType: STPPaymentMethodUSBankAccountType

    /// The name of the bank
    @objc public let bankName: String

    /// Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
    @objc public let fingerprint: String

    /// Last four digits of the bank account number
    @objc public let last4: String

    /// The token of the Linked Account used to create the payment method
    @objc public let linkedAccount: String?

    /// Contains information about US bank account networks that can be used
    @objc public let networks: STPPaymentMethodUSBankAccountNetworks?

    /// Routing number of the bank account
    @objc public let routingNumber: String

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    internal init(
        accountHolderType: STPPaymentMethodUSBankAccountHolderType,
        accountType: STPPaymentMethodUSBankAccountType,
        bankName: String,
        fingerprint: String,
        last4: String,
        linkedAccount: String?,
        networks: STPPaymentMethodUSBankAccountNetworks?,
        routingNumber: String,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.accountHolderType = accountHolderType
        self.accountType = accountType
        self.bankName = bankName
        self.fingerprint = fingerprint
        self.last4 = last4
        self.linkedAccount = linkedAccount
        self.networks = networks
        self.routingNumber = routingNumber
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
/// :nodoc:
extension STPPaymentMethodUSBankAccount: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
            let accountHolderTypeString = response["account_holder_type"] as? String,
            let accountTypeString = response["account_type"] as? String,
            let bankName = response["bank_name"] as? String,
            let fingerprint = response["fingerprint"] as? String,
            let last4 = response["last4"] as? String,
            let routingNumber = response["routing_number"] as? String
        else {
            return nil
        }
        var networks: STPPaymentMethodUSBankAccountNetworks?
        if let networksHash = response["networks"] as? [AnyHashable: Any],
            let supported = networksHash["supported"] as? [String]
        {
            let preferred = networksHash["preferred"] as? String
            networks = STPPaymentMethodUSBankAccountNetworks(
                preferred: preferred,
                supported: supported
            )
        }

        return STPPaymentMethodUSBankAccount(
            accountHolderType: STPPaymentMethodUSBankAccountHolderType(
                string: accountHolderTypeString
            ),
            accountType: STPPaymentMethodUSBankAccountType(string: accountTypeString),
            bankName: bankName,
            fingerprint: fingerprint,
            last4: last4,
            linkedAccount: response["financial_connections_account"] as? String,
            networks: networks,
            routingNumber: routingNumber,
            allResponseFields: response
        ) as? Self

    }
}

// MARK: - STPPaymentMethodUSBankAccountHolderType
/// Account holder type
@objc public enum STPPaymentMethodUSBankAccountHolderType: Int {
    /// This is an unknown type that's been added since the SDK
    /// was last updated.
    /// Update your SDK, or use the `allResponseFields`
    /// for custom handling.
    case unknown
    /// Account belongs to an individual
    case individual
    /// Account belongs to a company
    case company

    internal init(
        string: String?
    ) {
        guard let string = string else {
            self = .unknown
            return
        }
        switch string.lowercased() {
        case "individual":
            self = .individual
        case "company":
            self = .company
        default:
            self = .unknown
        }
    }

    internal var stringValue: String? {
        switch self {
        case .unknown:
            return nil
        case .individual:
            return "individual"
        case .company:
            return "company"
        }
    }

}

// MARK: - STPPaymentMethodUSBankAccountType
/// Account type
@objc public enum STPPaymentMethodUSBankAccountType: Int {
    /// This is an unknown type that's been added since the SDK
    /// was last updated.
    /// Update your SDK, or use the `allResponseFields`
    /// for custom handling.
    case unknown
    /// Bank account type is checking
    case checking
    /// Bank account type is savings
    case savings

    internal init(
        string: String?
    ) {
        guard let string = string else {
            self = .unknown
            return
        }

        switch string.lowercased() {
        case "checking":
            self = .checking
        case "savings":
            self = .savings
        default:
            self = .unknown
        }
    }

    internal var stringValue: String? {
        switch self {
        case .unknown:
            return nil
        case .checking:
            return "checking"
        case .savings:
            return "savings"
        }
    }
}

// MARK: - STPPaymentMethodUSBankAccountNetworks
/// Contains information about US bank account networks that can be used
public class STPPaymentMethodUSBankAccountNetworks: NSObject {

    /// The preferred network
    @objc public let preferred: String?

    /// All supported networks
    @objc public let supported: [String]

    internal init(
        preferred: String?,
        supported: [String]
    ) {
        self.preferred = preferred
        self.supported = supported
        super.init()
    }
}
