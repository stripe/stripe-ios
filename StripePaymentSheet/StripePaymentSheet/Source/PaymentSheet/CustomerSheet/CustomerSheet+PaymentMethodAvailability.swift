//
//  CustomerSheet+PaymentMethodAvailability.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

extension CustomerSheet {

    static var supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount]

    static func paymentSheetPaymentMethodTypes(requestedPaymentMethods: [STPPaymentMethodType]) -> [PaymentSheet.PaymentMethodType] {
        let filtered: [STPPaymentMethodType] = CustomerSheet.filteredPaymentMethods(requestedPaymentMethods: requestedPaymentMethods)

        var uniquePMTypes: Set<STPPaymentMethodType> = []

        var pmTypes: [PaymentSheet.PaymentMethodType] = []
        for pm in filtered {
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

    static func filteredPaymentMethods(requestedPaymentMethods: [STPPaymentMethodType]) -> [STPPaymentMethodType] {
        requestedPaymentMethods.filter { type in
            let isSupported = CustomerSheet.supportedPaymentMethods.contains(type)
            if type == .USBankAccount && !FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
                #if DEBUG
                print("[Stripe SDK]: CustomerSheet:\(PaymentSheet.PaymentMethodTypeRequirement.financialConnectionsSDK.debugDescription)")
                #endif
                return false
            }
            return isSupported
        }
    }
}
