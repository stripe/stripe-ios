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

    var isLinkUI: Bool {
        switch configuration {
        case .paymentElement(_, let isLinkUI):
            return isLinkUI
        case .customerSheet:
            return false
        }
    }

    var previouslyHadLinkSignupSelected: Bool {
        switch previousLinkInlineSignupAction {
        case .signupAndPay:
            return true
        default:
            return false
        }
    }

    func makeCard(linkAppearance: LinkAppearance? = nil) -> PaymentMethodElement {
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
            cardBrandFilter: configuration.cardBrandFilter,
            opensCardScannerAutomatically: configuration.opensCardScannerAutomatically,
            linkAppearance: linkAppearance
        )

        let shouldIncludeEmail = configuration.billingDetailsCollectionConfiguration.email == .always
        let shouldIncludePhone = configuration.billingDetailsCollectionConfiguration.phone == .always

        let billingAddressSection: PaymentMethodElementWrapper<AddressSectionElement>? = {
            let countries = configuration.billingDetailsCollectionConfiguration.allowedCountries.isEmpty
                ? nil
                : Array(configuration.billingDetailsCollectionConfiguration.allowedCountries)
            switch configuration.billingDetailsCollectionConfiguration.address {
            case .automatic:
                return makeBillingAddressSection(collectionMode: .countryAndPostal(), countries: countries, includeEmail: shouldIncludeEmail, includePhone: shouldIncludePhone)
            case .full:
                return makeBillingAddressSection(collectionMode: .autoCompletable, countries: countries, includeEmail: shouldIncludeEmail, includePhone: shouldIncludePhone)
            case .never:
                return nil
            }
        }()

        // Make section titled "Contact Information" w/ phone and email if merchant requires it and we didn't have a billing address section.
        let optionalPhoneAndEmailInformationSection: SectionElement? = {
            guard billingAddressSection == nil else {
                // We already included this information in the billing address section.
                return nil
            }
            let emailElement: Element? = shouldIncludeEmail ? makeEmail() : nil
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

        if case .paymentElement(let configuration, _) = configuration, let accountService, showLinkInlineSignup {
            // Restore the signup state on recreation
            let signupOptInInitialValue = signupOptInInitialValue || previouslyHadLinkSignupSelected
            let inlineSignupElement = LinkInlineSignupElement(
                configuration: configuration,
                linkAccount: linkAccount,
                country: countryCode,
                showCheckbox: !shouldDisplaySaveCheckbox,
                accountService: accountService,
                allowsDefaultOptIn: allowsLinkDefaultOptIn,
                signupOptInFeatureEnabled: signupOptInFeatureEnabled,
                signupOptInInitialValue: signupOptInInitialValue,
                analyticsHelper: analyticsHelper
            )
            elements.append(inlineSignupElement)
        }

        let mandate: SimpleMandateElement? = {
            if forceSaveFutureUseBehavior {
                // Respect this over all other configurations, since we're forcing SFU behavior and thus need to show a mandate.
                return makeMandate()
            }
            switch configuration.termsDisplayFor(paymentMethodType: .stripe(.card)) {
            case .never:
                return nil
            case .automatic:
                if isSettingUp {
                    return makeMandate()
                }
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
        let shouldCheckSignupCheckbox = showLinkInlineCardSignup && signupOptInFeatureEnabled && signupOptInInitialValue
        let shouldSignUpToLink = shouldCheckSignupCheckbox && !isLinkUI
        let variant: MandateVariant = forceSaveFutureUseBehavior
            ? .updated(shouldSignUpToLink: shouldSignUpToLink)
            : .original
        let mandateText = Self.makeMandateText(variant: variant, merchantName: configuration.merchantDisplayName)
        return makeMandate(mandateText: mandateText)
    }

    static func makeMandateText(
        variant: MandateVariant,
        merchantName: String
    ) -> NSAttributedString {
        return variant.create(forMerchant: merchantName)
    }
}
