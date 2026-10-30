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
    public var accountHolderTypeString: String?

    /// Account holder type
    public var accountHolderType: STPPaymentMethodUSBankAccountHolderType {
        get {
            return STPPaymentMethodUSBankAccountHolderType(string: accountHolderTypeString)
        }

        set {
            accountHolderTypeString = newValue.stringValue
        }
    }

    /// Account number of the bank account
    public var accountNumber: String?

    /// The raw underlying account type string sent to the server.
    /// You can use this if you want to create a param of a type not yet supported
    /// by the current version of the SDK's `STPPaymentMethodUSBankAccountType` enum.
    /// Setting this to a value not known by the SDK causes `accountType` to
    /// return `.unknown`
    public var accountTypeString: String?

    /// Account type
    public var accountType: STPPaymentMethodUSBankAccountType {
        get {
            return STPPaymentMethodUSBankAccountType(string: accountTypeString)
        }

        set {
            accountTypeString = newValue.stringValue
        }
    }

    /// Routing number of the bank account
    public var routingNumber: String?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Internal-only option to create directly from a link_account_session ID
    @_spi(InternalOnlyAPI) public var linkAccountSessionID: String?

}

// MARK: - STPFormEncodable
/// :nodoc:
extension STPPaymentMethodUSBankAccountParams: STPFormEncodable {
    public static func rootObjectName() -> String? {
        return "us_bank_account"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodUSBankAccountParams.accountHolderTypeString: "account_holder_type",
            \STPPaymentMethodUSBankAccountParams.accountNumber: "account_number",
            \STPPaymentMethodUSBankAccountParams.accountTypeString: "account_type",
            \STPPaymentMethodUSBankAccountParams.routingNumber: "routing_number",
            \STPPaymentMethodUSBankAccountParams.linkAccountSessionID: "link_account_session",
        ]
    }
}
