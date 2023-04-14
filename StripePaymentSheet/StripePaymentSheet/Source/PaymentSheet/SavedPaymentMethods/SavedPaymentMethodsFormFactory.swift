//
//  SavedPaymentMethodsFormFactory.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

class SavedPaymentMethodsFormFactory {

    let paymentMethod: PaymentSheet.PaymentMethodType
    let configuration: SavedPaymentMethodsSheet.Configuration
    let addressSpecProvider: AddressSpecProvider

    var theme: ElementsUITheme {
        return configuration.appearance.asElementsTheme
    }

    init(
        configuration: SavedPaymentMethodsSheet.Configuration,
        addressSpecProvider: AddressSpecProvider = .shared,
        paymentMethod: PaymentSheet.PaymentMethodType
    ) {
        self.configuration = configuration
        self.paymentMethod = paymentMethod
        self.addressSpecProvider = addressSpecProvider
    }

    func make() -> PaymentMethodElement? {
        if paymentMethod == .card {
            return makeCard(theme: theme)
        }

        assertionFailure("Currently only support cards")
        return nil
    }

    func makeCard(theme: ElementsUITheme = .default) -> PaymentMethodElement {
        let cardFormElement = FormElement(elements: [
            CardSection(theme: theme),
        ], theme: theme)
            return cardFormElement
    }
}
