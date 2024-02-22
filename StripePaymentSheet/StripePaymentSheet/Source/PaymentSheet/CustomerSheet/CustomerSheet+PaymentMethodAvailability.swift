//
//  CustomerSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

extension CustomerSheet {
    static let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]
    static func paymentMethodIsSupported(_ paymentMethod: STPPaymentMethodType,
                                         supportedPaymentMethods: [STPPaymentMethodType]) -> Bool {
        return supportedPaymentMethods.contains(where: {$0 == paymentMethod})
    }
}

extension Array where Element == STPPaymentMethodType {
    func customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: CustomerAdapter,
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
                if !customerAdapter.canCreateSetupIntents {
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

extension Array where Element == String {
    func customerSheetSupportedPaymentMethodTypes(_ supportedPaymentMethodTypes: [STPPaymentMethodType] = CustomerSheet.supportedPaymentMethods) -> Result<[STPPaymentMethodType]?, Error> {
        guard !self.isEmpty else {
            return .success(nil)
        }
        var unsupportedPMs: [String] = []
        var validPMs: [STPPaymentMethodType] = []

        for paymentMethodType in self {
            let stpPaymentMethodType = STPPaymentMethod.type(from: paymentMethodType)
            if !CustomerSheet.paymentMethodIsSupported(stpPaymentMethodType, supportedPaymentMethods: supportedPaymentMethodTypes){
                unsupportedPMs.append(paymentMethodType)
            } else {
                validPMs.append(stpPaymentMethodType)
            }
        }
        guard unsupportedPMs.isEmpty else {
            return .failure(CustomerSheetError.unsupportedPaymentMethodType(paymentMethodTypes: unsupportedPMs))
        }
        if validPMs.isEmpty {
            return .success(nil)
        }
        return .success(validPMs)
    }
}

