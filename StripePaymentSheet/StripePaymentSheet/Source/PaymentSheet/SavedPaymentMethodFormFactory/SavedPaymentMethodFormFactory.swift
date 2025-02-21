//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

class SavedPaymentMethodFormFactory {
    static func makePaymentMethodForm(viewModel: UpdatePaymentMethodViewModel) -> PaymentMethodElement {
        switch viewModel.paymentMethod.type {
        case .card:
            return makeCard(viewModel: viewModel)
        case .USBankAccount:
            return makeUSBankAccount(viewModel: viewModel)
        case .SEPADebit:
            return makeSEPADebit(viewModel: viewModel)
        default:
            fatalError("Cannot make payment method form for payment method type \(viewModel.paymentMethod.type).")
        }
    }
}
