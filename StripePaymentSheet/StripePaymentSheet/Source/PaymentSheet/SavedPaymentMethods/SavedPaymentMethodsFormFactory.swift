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
        // TODO: Figure out if we need to add checkbox -- probably not, basic integration add payment method does not.
//        let saveCheckbox = makeSaveCheckbox(
//            label: String.Localized.save_this_card_for_future_$merchant_payments(
//                merchantDisplayName: configuration.merchantDisplayName
//            )
//        )
//        let shouldDisplaySaveCheckbox: Bool = saveMode == .userSelectable && !canSaveToLink
        let cardFormElement = FormElement(elements: [
            CardSection(theme: theme),
            //shouldDisplaySaveCheckbox ? saveCheckbox : nil,
        ], theme: theme)
//        if isLinkEnabled {
//            return LinkEnabledPaymentMethodElement(
//                type: .card,
//                paymentMethodElement: cardFormElement,
//                configuration: configuration,
//                linkAccount: nil,
//                country: intent.countryCode
//            )
//        } else {
            return cardFormElement
//        }
    }
}
