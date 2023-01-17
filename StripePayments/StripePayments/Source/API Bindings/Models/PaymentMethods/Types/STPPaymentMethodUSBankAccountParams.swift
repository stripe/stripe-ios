//
//  STPPaymentMethodUSBankAccountParams.swift
//  StripePayments
//
//  Created by Cameron Sabol on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// An object representing parameters used to create a US Bank Account Payment Method
public class STPPaymentMethodUSBankAccountParams: NSObject {

    /// The raw underlying account holder type string sent to the server.
    /// You can use this if you want to create a param of a bank not yet supported
    /// by the current version of the SDK's `STPPaymentMethodUSBankAccountHolderType` enum.
    /// Setting this to a value not known by the SDK causes `accountHolderType` to
    /// return `.unknown`
    @objc public var accountHolderTypeString: String?

    /// Account holder type
    @objc public var accountHolderType: STPPaymentMethodUSBankAccountHolderType {
        get {
            return STPPaymentMethodUSBankAccountHolderType(string: accountHolderTypeString)
        }

        set {
            accountHolderTypeString = newValue.stringValue
        }
    }

    /// Account number of the bank account
    @objc public var accountNumber: String?

    /// The raw underlying account type string sent to the server.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPPaymentMethodUSBankAccountType` enum.
    /// Setting this to a value not known by the SDK causes `accountType` to
    /// return `.unknown`
    @objc public var accountTypeString: String?

    /// Account type
    @objc public var accountType: STPPaymentMethodUSBankAccountType {
        get {
            return STPPaymentMethodUSBankAccountType(string: accountTypeString)
        }

        set {
            accountTypeString = newValue.stringValue
        }
    }

    /// Routing number of the bank account
    @objc public var routingNumber: String?

    /// :nodoc:
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Internal-only option to create directly from a link_account_session ID
    @objc @_spi(STP) public var linkAccountSessionID: String?

}

// MARK: - STPFormEncodable
/// :nodoc:
extension STPPaymentMethodUSBankAccountParams: STPFormEncodable {
    public static func rootObjectName() -> String? {
        return "us_bank_account"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: accountHolderTypeString)): "account_holder_type",
            NSStringFromSelector(#selector(getter: accountNumber)): "account_number",
            NSStringFromSelector(#selector(getter: accountTypeString)): "account_type",
            NSStringFromSelector(#selector(getter: routingNumber)): "routing_number",
            NSStringFromSelector(#selector(getter: linkAccountSessionID)): "link_account_session",
        ]
    }
}
