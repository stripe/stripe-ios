//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

// Communicates back to caller if the initial state of the form is in an error state
typealias ErrorStateCallback = (Bool) -> Void

class SavedPaymentMethodFormFactory {
    var lastCardBrandLogSelectedEventSent: String?

    func makePaymentMethodForm(configuration: UpdatePaymentMethodViewController.Configuration, errorStateCallback: ErrorStateCallback) -> PaymentMethodElement {
        switch configuration.paymentMethod.type {
        case .card:
            return makeCard(configuration: configuration, errorStateCallback: errorStateCallback)
        case .USBankAccount:
            return makeUSBankAccount(configuration: configuration)
        case .SEPADebit:
            return makeSEPADebit(configuration: configuration)
        default:
            fatalError("Cannot make payment method form for payment method type \(configuration.paymentMethod.type).")
        }
    }
}
