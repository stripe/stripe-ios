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

private func transparentMaskViewBackgroundColor(componentBackground: UIColor) -> UIColor {
    let alpha: CGFloat = 0.075
    let colorMaskForLight = UIColor.black.withAlphaComponent(alpha)
    let colorMaskForDark = UIColor.white.withAlphaComponent(alpha)

    return componentBackground.isBright
    ? UIColor.dynamic(light: colorMaskForLight,
                      dark: colorMaskForDark)
    : UIColor.dynamic(light: colorMaskForDark,
                      dark: colorMaskForLight)
}

private func overlayColor(overlayColor: UIColor, baseColor: UIColor) -> UIColor {
    var r1: CGFloat = 0
    var g1: CGFloat = 0
    var b1: CGFloat = 0
    var alpha1: CGFloat = 0
    overlayColor.getRed(&r1, green: &g1, blue: &b1, alpha: &alpha1)

    var r2: CGFloat = 0
    var g2: CGFloat = 0
    var b2: CGFloat = 0
    var alpha2: CGFloat = 0
    baseColor.getRed(&r2, green: &g2, blue: &b2, alpha: &alpha2)

    let alphaResult = alpha1 + alpha2 * (1 - alpha1)

    let rResult = (r1 * alpha1 + r2 * alpha2 * (1 - alpha1)) / alphaResult
    let gResult = (g1 * alpha1 + g2 * alpha2 * (1 - alpha1)) / alphaResult
    let bResult = (b1 * alpha1 + b2 * alpha2 * (1 - alpha1)) / alphaResult

    return UIColor(red: rResult, green: gResult, blue: bResult, alpha: alphaResult)
}

// calculate the resulting color of the mask overlaying the component background
private func disabledBackgroundColor(componentBackground: UIColor) -> UIColor {
    let mask = transparentMaskViewBackgroundColor(componentBackground: componentBackground)
    return overlayColor(overlayColor: mask, baseColor: componentBackground)
}

class SavedPaymentMethodFormFactory {
    let viewModel: UpdatePaymentMethodViewModel
    weak var delegate: SavedPaymentMethodFormFactoryDelegate?

    init(viewModel: UpdatePaymentMethodViewModel) {
        var disabledAppearance = viewModel.appearance
        disabledAppearance.colors.componentBackground = disabledBackgroundColor(componentBackground: disabledAppearance.colors.componentBackground)
        self.viewModel = UpdatePaymentMethodViewModel(paymentMethod: viewModel.paymentMethod, appearance: disabledAppearance, hostedSurface: viewModel.hostedSurface, cardBrandFilter: viewModel.cardBrandFilter, canEdit: viewModel.canEdit, canRemove: viewModel.canRemove)
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
