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

        var pmTypes: [PaymentSheet.PaymentMethodType] = []
        for pm in filtered {
            guard let paymentMethodString = STPPaymentMethod.string(from: pm) else {
                continue
            }
            pmTypes += [PaymentSheet.PaymentMethodType(from: paymentMethodString)]
        }
        return pmTypes
    }

    static func filteredPaymentMethods(requestedPaymentMethods: [STPPaymentMethodType]) -> [STPPaymentMethodType] {
        requestedPaymentMethods.filter { type in
            CustomerSheet.supportedPaymentMethods.contains(type)
        }
    }
}
