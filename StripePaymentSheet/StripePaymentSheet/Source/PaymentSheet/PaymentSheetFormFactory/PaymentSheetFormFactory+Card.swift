//
//  PaymentSheetFormFactory+Card.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheetFormFactory {
    func makeCard() -> PaymentMethodElement {
        let showLinkInlineSignup = showLinkInlineCardSignup
        let defaultCheckbox: Element? = {
            guard allowsSetAsDefaultPM else {
                return nil
            }
            let defaultCheckbox = makeDefaultCheckbox()
            return shouldDisplayDefaultCheckbox ? defaultCheckbox : SectionElement.HiddenElement(defaultCheckbox)
        }()
        let saveCheckbox = makeSaveCheckbox(
            label: String.Localized.save_payment_details_for_future_$merchant_payments(
                merchantDisplayName: configuration.merchantDisplayName
            )
        ) { selected in
            if let defaultCheckbox {
                UIView.transition(with: defaultCheckbox.view, duration: 0.2,
                                  options: .transitionCrossDissolve,
                                  animations: {
                    defaultCheckbox.view.isHidden = !selected
                })
            }
        }
        defaultCheckbox?.view.isHidden = !saveCheckbox.element.isSelected

        // Make section titled "Contact Information" w/ phone and email if merchant requires it.
        let optionalPhoneAndEmailInformationSection: SectionElement? = {
            let emailElement: Element? = configuration.billingDetailsCollectionConfiguration.email == .always ? makeEmail() : nil
            let shouldIncludePhone = configuration.billingDetailsCollectionConfiguration.phone == .always
            let phoneElement: Element? = shouldIncludePhone ? makePhone() : nil
            let contactInformationElements = [emailElement, phoneElement].compactMap { $0 }
            guard !contactInformationElements.isEmpty else {
                return nil
            }
            return SectionElement(
                title: .Localized.contact_information,
                elements: contactInformationElements,
                theme: theme
            )
        }()

        let previousCardInput = previousCustomerInput?.paymentMethodParams.card
        let formattedExpiry: String? = {
            guard let expiryMonth = previousCardInput?.expMonth?.intValue, let expiryYear = previousCardInput?.expYear?.intValue else {
                return nil
            }
            return String(format: "%02d%02d", expiryMonth, expiryYear % 100) // Modulo 100 as safeguard to get last 2 digits of the expiry
        }()
        let cardDefaultValues = CardSectionElement.DefaultValues(
            name: defaultBillingDetails().name,
            pan: previousCardInput?.number,
            cvc: previousCardInput?.cvc,
            expiry: formattedExpiry
        )

        let cardSection = CardSectionElement(
            collectName: configuration.billingDetailsCollectionConfiguration.name == .always,
            defaultValues: cardDefaultValues,
            preferredNetworks: configuration.preferredNetworks,
            cardBrandChoiceEligible: cardBrandChoiceEligible,
            hostedSurface: .init(config: configuration),
            theme: theme,
            analyticsHelper: analyticsHelper,
            cardBrandFilter: configuration.cardBrandFilter
        )

        let billingAddressSection: PaymentMethodElementWrapper<AddressSectionElement>? = {
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                return makeBillingAddressSection(collectionMode: .countryAndPostal(), countries: nil)
            case .full:
                return makeBillingAddressSection(collectionMode: .autoCompletable, countries: nil)
            case .never:
                return nil
            }
        }()

        let phoneElement = optionalPhoneAndEmailInformationSection?.elements.compactMap {
            $0 as? PaymentMethodElementWrapper<PhoneNumberElement>
        }.first

        connectBillingDetailsFields(
            countryElement: nil,
            addressElement: billingAddressSection,
            phoneElement: phoneElement)

        var elements: [Element?] = [
            optionalPhoneAndEmailInformationSection,
            cardSection,
            billingAddressSection,
            shouldDisplaySaveCheckbox ? saveCheckbox : nil,
            defaultCheckbox,
        ]

        if case .paymentElement(let configuration) = configuration, let accountService, showLinkInlineSignup {
            let inlineSignupElement = LinkInlineSignupElement(
                configuration: configuration,
                linkAccount: linkAccount,
                country: countryCode,
                showCheckbox: !shouldDisplaySaveCheckbox,
                accountService: accountService,
                allowsDefaultOptIn: allowsLinkDefaultOptIn,
                signupOptInFeatureEnabled: signupOptInFeatureEnabled,
                signupOptInInitialValue: signupOptInInitialValue
            )
            elements.append(inlineSignupElement)
        }

        let mandate: SimpleMandateElement? = {
            if isSettingUp || signupOptInFeatureEnabled {
                return makeMandate()
            }
            return nil
        }()
        elements.append(mandate)

        var customSpacing: [(Element, CGFloat)] = []
        if configuration.linkPaymentMethodsOnly {
            customSpacing.append((cardSection, LinkUI.largeContentSpacing))
        }

        return FormElement(
            elements: elements,
            theme: theme,
            customSpacing: customSpacing)
    }

    private func makeMandate() -> SimpleMandateElement {
        let mandateText = Self.makeMandateText(
            linkSignupOptInFeatureEnabled: signupOptInFeatureEnabled,
            shouldSaveToLink: signupOptInInitialValue,
            merchantName: configuration.merchantDisplayName
        )
        return makeMandate(mandateText: mandateText)
    }

    static func makeMandateText(
        linkSignupOptInFeatureEnabled: Bool,
        shouldSaveToLink: Bool,
        merchantName: String
    ) -> NSAttributedString {
        let formatText = if linkSignupOptInFeatureEnabled {
            if shouldSaveToLink {
                String.Localized.by_continuing_you_agree_to_save_your_information_to_merchant_and_link
            } else {
                String.Localized.by_continuing_you_agree_to_save_your_information_to_merchant
            }
        } else {
            String.Localized.by_providing_your_card_information_text
        }

        let terms = String(format: formatText, merchantName).removeTrailingDots()

        if linkSignupOptInFeatureEnabled && shouldSaveToLink {
            let links = [
                "link": URL(string: "https://link.com")!,
                "terms": URL(string: "https://link.com/terms")!,
                "privacy": URL(string: "https://link.com/privacy")!,
            ]
            return STPStringUtils.applyLinksToString(template: terms, links: links)
        } else {
            return NSAttributedString(string: terms)
        }
    }
}

private extension String {
    func removeTrailingDots() -> String {
        return hasSuffix("..") ? String(dropLast()) : self
    }
}
