//
//  MandateTextProvider.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/3/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

protocol MandateTextProvider {
    func mandate(for paymentMethodType: PaymentSheet.PaymentMethodType?, savedPaymentMethod: STPPaymentMethod?, bottomNoticeAttributedString: NSAttributedString?) -> NSAttributedString?
}

/// A class that can provide the attributed string for a given payment method type and configuration for the vertical list of PMs.
class VerticalListMandateProvider: MandateTextProvider {
    private let configuration: PaymentElementConfiguration
    private let elementsSession: STPElementsSession
    private let intent: Intent
    private let analyticsHelper: PaymentSheetAnalyticsHelper

    init(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession, intent: Intent, analyticsHelper: PaymentSheetAnalyticsHelper) {
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.intent = intent
        self.analyticsHelper = analyticsHelper
    }

    /// Builds the attributed string for a given payment method type.
    /// - Parameter paymentMethodType: The payment method type who's mandate should be constructed
    /// - Parameter savedPaymentMethod: The currently selected saved payment method if any
    /// - Parameter bottomNoticeAttributedString: Passing this in just makes this method return it
    /// - Returns: An `NSAttributedString` representing the mandate to be displayed for `paymentMethodType` or `nil` if there is no mandate.
    func mandate(for paymentMethodType: PaymentSheet.PaymentMethodType?, savedPaymentMethod: STPPaymentMethod?, bottomNoticeAttributedString: NSAttributedString? = nil) -> NSAttributedString? {
        guard let paymentMethodType else { return nil }
        if savedPaymentMethod != nil {
            // 1. For saved PMs, manually build mandates
            switch paymentMethodType {
            case .stripe(.USBankAccount):
                return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(alignment: .natural, theme: configuration.appearance.asElementsTheme)
            case .stripe(.SEPADebit):
                return .init(string: String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName))
            case .stripe(.link): // Instant Debits
                return bottomNoticeAttributedString
            case .stripe(.card) where elementsSession.isLinkCardBrand: // Panther
                return bottomNoticeAttributedString
            default:
                return nil
            }
        } else {
            // 2. For new PMs, see if we have a bottomNoticeAttributedString, typically just US bank acct. and Link Instant Debits
            if let bottomNoticeAttributedString {
                return bottomNoticeAttributedString
            }
            // 3. If not, generate the form
            let form = PaymentSheetFormFactory(
                intent: intent,
                elementsSession: elementsSession,
                configuration: .paymentElement(configuration),
                paymentMethod: paymentMethodType,
                previousCustomerInput: nil,
                linkAccount: LinkAccountContext.shared.account,
                accountService: LinkAccountService(apiClient: configuration.apiClient, elementsSession: elementsSession),
                analyticsHelper: analyticsHelper
            ).make()

            guard !form.collectsUserInput else {
                // If it collects user input, the mandate will be displayed in the form and not here
                return nil
            }
            // Get the mandate from the form, if available
            // 🙋‍♂️ Note: assumes mandates are SimpleMandateElement!
            if let mandateText = form.getAllUnwrappedSubElements().compactMap({ $0 as? SimpleMandateElement }).first?.mandateTextView.attributedText, !mandateText.string.isEmpty {
                return mandateText
            }
            return nil
        }
    }
}
