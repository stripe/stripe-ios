//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

@_spi(STP) import StripePayments

class SavedPaymentMethodFormFactory {
    func makePaymentMethodForm(configuration: UpdatePaymentMethodViewController.Configuration) -> PaymentMethodElement {
        switch configuration.paymentMethod.type {
        case .card:
            if configuration.paymentMethod.isLinkPaymentMethod {
                return makeLink(configuration: configuration)
            } else {
                return makeCard(configuration: configuration)
            }
        case .USBankAccount:
            return makeUSBankAccount(configuration: configuration)
        case .SEPADebit:
            return makeSEPADebit(configuration: configuration)
        case .link:
            return makeLink(configuration: configuration)
        default:
            fatalError("Cannot make payment method form for payment method type \(configuration.paymentMethod.type).")
        }
    }
}
