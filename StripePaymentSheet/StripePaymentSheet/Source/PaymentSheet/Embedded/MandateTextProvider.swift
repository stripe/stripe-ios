//
//  MandateTextProvider.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/3/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol MandateTextProvider {
    func mandate(for paymentMethodType: PaymentSheet.PaymentMethodType?, savedPaymentMethod: STPPaymentMethod?, bottomNoticeAttributedString: NSAttributedString?) -> NSAttributedString?
}

/// A class that can provide the attributed string for a given payment method type and configuration
class FormMandateProvider: MandateTextProvider {
    private let configuration: PaymentElementConfiguration
    private let elementsSession: STPElementsSession
    private let intent: Intent

    init(configuration: PaymentElementConfiguration, elementsSession: STPElementsSession, intent: Intent) {
        self.configuration = configuration
        self.elementsSession = elementsSession
        self.intent = intent
    }

    /// Builds the attributed string for a given payment method type
    /// - Parameter paymentMethodType: The payment method type who's mandate should be constructed
    /// - Parameter savedPaymentMethod: The currently selected saved payment method if any
    /// - Parameter bottomNoticeAttributedString: Passing this in just makes this method return it as long as `configuration` doesn't hide mandate text
    /// - Returns: An `NSAttributedString` representing the mandate to be displayed for `paymentMethodType`, returns `nil` if no mandate should be shown
    func mandate(for paymentMethodType: PaymentSheet.PaymentMethodType?, savedPaymentMethod: STPPaymentMethod?, bottomNoticeAttributedString: NSAttributedString? = nil) -> NSAttributedString? {
        // Merchant will display the mandate
        guard !configuration.hidesMandateText else {  return nil }

        let newMandateText: NSAttributedString? = {
            guard let paymentMethodType else { return nil }
            if savedPaymentMethod != nil {
                // 1. For saved PMs, manually build mandates
                switch paymentMethodType {
                case .stripe(.USBankAccount):
                    return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(alignment: .natural, theme: configuration.appearance.asElementsTheme)
                case .stripe(.SEPADebit):
                    return .init(string: String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName))
                default:
                    return nil
                }
            } else {
                // 2. For new PMs, see if we have a bottomNoticeAttributedString, typically just US bank acct. and Link Instant Debits
                if let bottomNoticeAttributedString {
                    return bottomNoticeAttributedString
                }
                // 3. If not, generate the form
                let form = PaymentMethodFormViewController(
                    type: paymentMethodType,
                    intent: intent,
                    elementsSession: elementsSession,
                    previousCustomerInput: nil,
                    formCache: .init(),
                    configuration: configuration,
                    headerView: nil,
                    analyticsHelper: .init(isCustom: false, configuration: PaymentSheet.Configuration()), // Dummy, not used
                    delegate: self
                ).form
                guard !form.collectsUserInput else {
                    // If it collects user input, the mandate will be displayed in the form and not here
                    return nil
                }
                // Get the mandate from the form, if available
                // 🙋‍♂️ Note: assumes mandates are SimpleMandateElement!
                return form.getAllUnwrappedSubElements().compactMap({ $0 as? SimpleMandateElement }).first?.mandateTextView.attributedText
            }
        }()

        return newMandateText
    }
}

extension PaymentElementConfiguration {
    var hidesMandateText: Bool {
        if let embeddedConfig = self as? EmbeddedPaymentElement.Configuration {
            return embeddedConfig.hidesMandateText
        }

        return false
    }
}

// MARK: PaymentMethodFormViewControllerDelegate

extension FormMandateProvider: PaymentMethodFormViewControllerDelegate {

    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        // no-op
    }

    func updateErrorLabel(for error: Error?) {
        // no-op
    }
}
