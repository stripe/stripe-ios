//
//  SavedPaymentMethodFormFactory.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/20/24.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodFormFactoryDelegate: AnyObject {
    func didUpdate(_: Element)
}

class SavedPaymentMethodFormFactory {
    let viewModel: UpdatePaymentMethodViewModel
    weak var delegate: SavedPaymentMethodFormFactoryDelegate?

    var lastCardBrandLogSelectedEventSent: String?
    init(viewModel: UpdatePaymentMethodViewModel) {
        self.viewModel = viewModel
    }

    func makePaymentMethodForm() -> UIView {
        switch viewModel.paymentMethod.type {
        case .card:
            return savedCardForm.view
        case .USBankAccount:
            return makeUSBankAccount()
        case .SEPADebit:
            return makeSEPADebit()
        default:
            fatalError("Cannot make payment method form for payment method type \(viewModel.paymentMethod.type).")
        }
    }

    private(set) lazy var savedCardForm: PaymentMethodElement = {
       return makeCard()
    }()
}

// MARK: ElementDelegate
extension SavedPaymentMethodFormFactory: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        switch viewModel.paymentMethod.type {
        case .card:
            delegate?.didUpdate(element)
        default:
            break
        }
    }
}
