//
//  CustomerSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

extension CustomerSheet {
    static let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
    static let supportedDefaultPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]
}

extension Array where Element == STPPaymentMethodType {
    func customerSheetSupportedPaymentMethodTypesForAdd(canCreateSetupIntents: Bool,
                                                        supportedPaymentMethods: [STPPaymentMethodType] = CustomerSheet.supportedPaymentMethods) -> [STPPaymentMethodType] {
        return self.filter { type in
            var isSupported = supportedPaymentMethods.contains(type)
            if type == .USBankAccount {
                if !FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
                    #if DEBUG
                    print("[Stripe SDK]: CustomerSheet:\(PaymentSheet.PaymentMethodTypeRequirement.financialConnectionsSDK.debugDescription)")
                    #endif
                    isSupported = false
                }
                if !canCreateSetupIntents {
                    #if DEBUG
                    print("[Stripe SDK]: CustomerSheet - customerAdapater must be able to create setupIntents")
                    #endif
                    isSupported = false
                }
            }
            return isSupported
        }
    }

    // Internal Helper used for displaying payment method types to add
    func toPaymentSheetPaymentMethodTypes() -> [PaymentSheet.PaymentMethodType] {
        var uniquePMTypes: Set<STPPaymentMethodType> = []

        var pmTypes: [PaymentSheet.PaymentMethodType] = []
        for pm in self {
            guard let paymentMethodString = STPPaymentMethod.string(from: pm) else {
                continue
            }
            if uniquePMTypes.contains(pm) {
                #if DEBUG
                print("[Stripe SDK]: CustomerSheet found duplicate payment method:\(paymentMethodString)")
                #endif
            } else {
                uniquePMTypes.insert(pm)
                pmTypes += [.stripe(pm)]
            }
        }
        return pmTypes
    }
}

extension CustomerSheet {
    /// Given a list of paymentMethodTypes, return an array of corresponding deduped list of STPPaymentMethodType that are supported
    /// within customer sheet.  If any unsupported payment method types are passed in, return an error.
    static func customerSheetSupportedPaymentMethodTypes(_ paymentMethodTypes: [String]) -> Result<[STPPaymentMethodType]?, Error> {
        guard !paymentMethodTypes.isEmpty else {
            return .success(nil)
        }
        var unsupportedPMs: [String] = []
        var unsupportedPMsSet: Set<String> = []
        var validPMs: [STPPaymentMethodType] = []
        var validPMsSet: Set<STPPaymentMethodType> = []

        for paymentMethodType in paymentMethodTypes {
            let stpPaymentMethodType = STPPaymentMethod.type(from: paymentMethodType)
            if !CustomerSheet.supportedPaymentMethods.contains(where: { $0 == stpPaymentMethodType }) {
                if !unsupportedPMsSet.contains(paymentMethodType) {
                    unsupportedPMsSet.insert(paymentMethodType)
                    unsupportedPMs.append(paymentMethodType)
                }
            } else {
                if !validPMsSet.contains(stpPaymentMethodType) {
                    validPMsSet.insert(stpPaymentMethodType)
                    validPMs.append(stpPaymentMethodType)
                }
            }
        }
        guard unsupportedPMs.isEmpty else {
            return .failure(CustomerSheetError.unsupportedPaymentMethodType(paymentMethodTypes: unsupportedPMs))
        }
        return .success(validPMs)
    }
}
