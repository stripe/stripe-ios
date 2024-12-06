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
    func didUpdate(_: Element, shouldEnableSaveButton: Bool)
}

class SavedPaymentMethodFormFactory {
    let viewModel: UpdatePaymentMethodViewModel
    weak var delegate: SavedPaymentMethodFormFactoryDelegate?

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

    private lazy var savedCardForm: Element = {
       return makeCard()
    }()

    func transparentMaskViewBackgroundColor() -> UIColor {
        let alpha: CGFloat = 0.075
        let colorMaskForLight = UIColor.black.withAlphaComponent(alpha)
        let colorMaskForDark = UIColor.white.withAlphaComponent(alpha)

        return viewModel.appearance.colors.componentBackground.isBright
        ? UIColor.dynamic(light: colorMaskForLight,
                          dark: colorMaskForDark)
        : UIColor.dynamic(light: colorMaskForDark,
                          dark: colorMaskForLight)
    }
}

// MARK: ElementDelegate
extension SavedPaymentMethodFormFactory: ElementDelegate {
    func continueToNextField(element: Element) {
        // no-op
    }

    func didUpdate(element: Element) {
        switch viewModel.paymentMethod.type {
        case .card:
            delegate?.didUpdate(_: element, shouldEnableSaveButton: viewModel.selectedCardBrand != viewModel.paymentMethod.card?.preferredDisplayBrand)
        default:
            break
        }
    }
}
