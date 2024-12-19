//
//  UpdatePaymentMethodViewModel.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 11/15/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

// calculate the resulting color of the mask overlaying the component background
private func disabledBackgroundColor(componentBackground: UIColor) -> UIColor {
    let alpha: CGFloat = 0.075
    let colorMaskForLight = UIColor.black.withAlphaComponent(alpha)
    let colorMaskForDark = UIColor.white.withAlphaComponent(alpha)

    let lightModeComponentBackground = componentBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    let darkModeComponentBackground = componentBackground.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
    return componentBackground.isBright
        ? UIColor.dynamic(light: overlayColor(overlayColor: colorMaskForLight, baseColor: lightModeComponentBackground),
                          dark: overlayColor(overlayColor: colorMaskForDark, baseColor: darkModeComponentBackground))
        : UIColor.dynamic(light: overlayColor(overlayColor: colorMaskForDark, baseColor: darkModeComponentBackground),
                          dark: overlayColor(overlayColor: colorMaskForLight, baseColor: lightModeComponentBackground))
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

class UpdatePaymentMethodViewModel {
    static let supportedPaymentMethods: [STPPaymentMethodType] = [.card, .USBankAccount, .SEPADebit]

    let paymentMethod: STPPaymentMethod
    let appearance: PaymentSheet.Appearance
    let hostedSurface: HostedSurface
    let cardBrandFilter: CardBrandFilter
    let canEdit: Bool
    let canRemove: Bool

    var selectedCardBrand: STPCardBrand?
    var errorState: Bool = false

    lazy var header: String = {
        switch paymentMethod.type {
        case .card:
            return .Localized.manage_card
        case .USBankAccount:
            return .Localized.manage_us_bank_account
        case .SEPADebit:
            return .Localized.manage_sepa_debit
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethod.type)")
        }
    }()

    lazy var footnote: String = {
        switch paymentMethod.type {
        case .card:
            return canEdit ? .Localized.only_card_brand_can_be_changed : .Localized.card_details_cannot_be_changed
        case .USBankAccount:
            return .Localized.bank_account_details_cannot_be_changed
        case .SEPADebit:
            return .Localized.sepa_debit_details_cannot_be_changed
        default:
            fatalError("Updating payment method has not been implemented for \(paymentMethod.type)")
        }
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, hostedSurface: HostedSurface, cardBrandFilter: CardBrandFilter = .default, canEdit: Bool, canRemove: Bool) {
        guard UpdatePaymentMethodViewModel.supportedPaymentMethods.contains(paymentMethod.type) else {
            fatalError("Unsupported payment type \(paymentMethod.type) in UpdatePaymentMethodViewModel")
        }
        self.paymentMethod = paymentMethod
        var disabledAppearance = appearance
        disabledAppearance.colors.componentBackground = disabledBackgroundColor(componentBackground:    disabledAppearance.colors.componentBackground)
        self.appearance = disabledAppearance
        self.hostedSurface = hostedSurface
        self.cardBrandFilter = cardBrandFilter
        self.canEdit = canEdit
        self.canRemove = canRemove
    }
}
