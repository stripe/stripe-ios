//
//  CheckoutSessionsConfiguration.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/27/26.
//

import Foundation
@_spi(STP) import StripePayments
import UIKit

/// Adapts an existing payment-element configuration to use Checkout Session customer data.
struct CheckoutSessionsConfiguration: PaymentElementConfiguration {

    private var base: PaymentElementConfiguration
    let customerProvider: CustomerProvider

    var customer: PaymentSheet.CustomerConfiguration? {
        get { base.customer }
        set { base.customer = newValue }
    }

    init(base: PaymentElementConfiguration, session: CheckoutController.Session) {
        self.base = base
        self.customerProvider = CustomerProvider(checkoutSession: session)
    }

    var allowsDelayedPaymentMethods: Bool {
        get { base.allowsDelayedPaymentMethods }
        set { base.allowsDelayedPaymentMethods = newValue }
    }

    var allowsPaymentMethodsRequiringShippingAddress: Bool {
        get { base.allowsPaymentMethodsRequiringShippingAddress }
        set { base.allowsPaymentMethodsRequiringShippingAddress = newValue }
    }

    var apiClient: STPAPIClient {
        get { base.apiClient }
        set { base.apiClient = newValue }
    }

    var applePay: PaymentSheet.ApplePayConfiguration? {
        get { base.applePay }
        set { base.applePay = newValue }
    }

    var link: PaymentSheet.LinkConfiguration {
        get { base.link }
        set { base.link = newValue }
    }

    var primaryButtonColor: UIColor? {
        get { base.primaryButtonColor }
        set { base.primaryButtonColor = newValue }
    }

    var primaryButtonLabel: String? {
        get { base.primaryButtonLabel }
        set { base.primaryButtonLabel = newValue }
    }

    var style: PaymentSheet.UserInterfaceStyle {
        get { base.style }
        set { base.style = newValue }
    }

    var merchantDisplayName: String {
        get { base.merchantDisplayName }
        set { base.merchantDisplayName = newValue }
    }

    var returnURL: String? {
        get { base.returnURL }
        set { base.returnURL = newValue }
    }

    var defaultBillingDetails: PaymentSheet.BillingDetails {
        get { base.defaultBillingDetails }
        set { base.defaultBillingDetails = newValue }
    }

    var savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior {
        get { base.savePaymentMethodOptInBehavior }
        set { base.savePaymentMethodOptInBehavior = newValue }
    }

    var appearance: PaymentSheet.Appearance {
        get { base.appearance }
        set { base.appearance = newValue }
    }

    var shippingDetails: () -> AddressViewController.AddressDetails? {
        get { base.shippingDetails }
        set { base.shippingDetails = newValue }
    }

    var preferredNetworks: [STPCardBrand]? {
        get { base.preferredNetworks }
        set { base.preferredNetworks = newValue }
    }

    var userOverrideCountry: String? {
        get { base.userOverrideCountry }
        set { base.userOverrideCountry = newValue }
    }

    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        get { base.billingDetailsCollectionConfiguration }
        set { base.billingDetailsCollectionConfiguration = newValue }
    }

    var removeSavedPaymentMethodMessage: String? {
        get { base.removeSavedPaymentMethodMessage }
        set { base.removeSavedPaymentMethodMessage = newValue }
    }

    var externalPaymentMethodConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration? {
        get { base.externalPaymentMethodConfiguration }
        set { base.externalPaymentMethodConfiguration = newValue }
    }

    var customPaymentMethodConfiguration: PaymentSheet.CustomPaymentMethodConfiguration? {
        get { base.customPaymentMethodConfiguration }
        set { base.customPaymentMethodConfiguration = newValue }
    }

    var paymentMethodOrder: [String]? {
        get { base.paymentMethodOrder }
        set { base.paymentMethodOrder = newValue }
    }

    var allowsRemovalOfLastSavedPaymentMethod: Bool {
        get { base.allowsRemovalOfLastSavedPaymentMethod }
        set { base.allowsRemovalOfLastSavedPaymentMethod = newValue }
    }

    var cardBrandAcceptance: PaymentSheet.CardBrandAcceptance {
        get { base.cardBrandAcceptance }
        set { base.cardBrandAcceptance = newValue }
    }

    var allowedCardFundingTypes: PaymentSheet.CardFundingType {
        get { base.allowedCardFundingTypes }
        set { base.allowedCardFundingTypes = newValue }
    }

    var analyticPayload: [String: Any] {
        var payload = base.analyticPayload
        payload["customer"] = customerProvider.hasCustomer
        payload["customer_access_provider"] = customerProvider.analyticValue
        return payload
    }

    var disableWalletPaymentMethodFiltering: Bool {
        get { base.disableWalletPaymentMethodFiltering }
        set { base.disableWalletPaymentMethodFiltering = newValue }
    }

    var linkPaymentMethodsOnly: Bool {
        get { base.linkPaymentMethodsOnly }
        set { base.linkPaymentMethodsOnly = newValue }
    }

    var opensCardScannerAutomatically: Bool {
        get { base.opensCardScannerAutomatically }
        set { base.opensCardScannerAutomatically = newValue }
    }

    var termsDisplay: [STPPaymentMethodType: PaymentSheet.TermsDisplay] {
        return base.termsDisplay
    }

    var embeddedConfiguration: EmbeddedPaymentElement.Configuration? {
        return base.embeddedConfiguration
    }

    func resolveLayout(
        elementsSession: STPElementsSession,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    ) -> PaymentSheet.PaymentMethodLayout.ResolvedLayout {
        return base.resolveLayout(
            elementsSession: elementsSession,
            paymentMethodTypes: paymentMethodTypes
        )
    }
}

extension PaymentSheet.InitializationMode {
    @MainActor
    func paymentElementConfiguration(
        basedOn configuration: PaymentElementConfiguration
    ) -> PaymentElementConfiguration {
        guard case .checkout(let checkout) = self else {
            return configuration
        }
        return CheckoutSessionsConfiguration(
            base: configuration,
            session: checkout.session
        )
    }
}
