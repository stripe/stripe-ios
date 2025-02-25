//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

class SavedPaymentMethodFormFactory {
    func makePaymentMethodForm(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        switch configuration.paymentMethod.type {
        case .card:
            return makeCard(configuration: configuration)
        case .USBankAccount:
            return makeUSBankAccount(configuration: configuration)
        case .SEPADebit:
            return makeSEPADebit(configuration: configuration)
        default:
            fatalError("Cannot make payment method form for payment method type \(configuration.paymentMethod.type).")
        }
    }
}
