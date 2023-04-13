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
    let intent: Intent?
    let configuration: SavedPaymentMethodsSheet.Configuration
    let addressSpecProvider: AddressSpecProvider

    var theme: ElementsUITheme {
        return configuration.appearance.asElementsTheme
    }

    init(
        intent: Intent?,
        configuration: SavedPaymentMethodsSheet.Configuration,
        addressSpecProvider: AddressSpecProvider = .shared,
        paymentMethod: PaymentSheet.PaymentMethodType
    ) {
        self.intent = intent
        self.configuration = configuration
        self.paymentMethod = paymentMethod
        self.addressSpecProvider = addressSpecProvider
    }

    func make() -> PaymentMethodElement {
        if paymentMethod == .card {
            return makeCard(theme: theme)
        }
        assert(false, "Currently only support cards")
    }

    func makeCard(theme: ElementsUITheme = .default) -> PaymentMethodElement {
        let cardFormElement = FormElement(elements: [
            CardSection(theme: theme),
        ], theme: theme)
            return cardFormElement
    }
}
