//
//  CustomerSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

extension CustomerSheet {
    static var supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]
}

extension CustomerSheet.Configuration {

    // Called internally from CustomerSheet to determine what payment methods to query for
    func customerSheetSupportedPaymentMethodTypes(customerAdapter: CustomerAdapter) -> [STPPaymentMethodType] {
        self.paymentMethodTypes.filter { type in
            var isSupported = CustomerSheet.supportedPaymentMethods.contains(type)
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
}

extension Array where Element == STPPaymentMethodType {
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
                pmTypes += [PaymentSheet.PaymentMethodType(from: paymentMethodString)]
            }
        }
        return pmTypes
    }
}
