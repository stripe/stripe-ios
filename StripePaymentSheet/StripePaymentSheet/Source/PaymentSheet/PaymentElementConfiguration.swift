//
//  PaymentElementConfiguration.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/1/24.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Represents shared configuration properties between integration surfaces in mobile payment element.
/// - Note: See the concrete implementations of `PaymentElementConfiguration` for detailed doc comments.
/// - Note: Not currently used by CustomerSheet.
protocol PaymentElementConfiguration: PaymentMethodRequirementProvider {
    var allowsDelayedPaymentMethods: Bool { get set }
    var allowsPaymentMethodsRequiringShippingAddress: Bool { get set }
    var apiClient: STPAPIClient { get set }
    var applePay: PaymentSheet.ApplePayConfiguration? { get set }
    var link: PaymentSheet.LinkConfiguration { get set }
    var primaryButtonColor: UIColor? { get set }
    var primaryButtonLabel: String? { get set }
    var style: PaymentSheet.UserInterfaceStyle { get set }
    var customer: PaymentSheet.CustomerConfiguration? { get set }
    var merchantDisplayName: String { get set }
    var returnURL: String? { get set }
    var defaultBillingDetails: PaymentSheet.BillingDetails { get set }
    var savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior { get set }
    var appearance: PaymentSheet.Appearance { get set }
    var shippingDetails: () -> AddressViewController.AddressDetails? { get set }
    var preferredNetworks: [STPCardBrand]? { get set }
    var userOverrideCountry: String? { get set }
    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration { get set }
    var removeSavedPaymentMethodMessage: String? { get set }
    var externalPaymentMethodConfiguration: PaymentSheet.ExternalPaymentMethodConfiguration? { get set }
    var customPaymentMethodConfiguration: PaymentSheet.CustomPaymentMethodConfiguration? { get set }
    var paymentMethodOrder: [String]? { get set }
    var allowsRemovalOfLastSavedPaymentMethod: Bool { get set }
    var cardBrandAcceptance: PaymentSheet.CardBrandAcceptance { get set }
    var analyticPayload: [String: Any] { get }
    var disableWalletPaymentMethodFiltering: Bool { get set }
    var linkPaymentMethodsOnly: Bool { get set }
    var paymentMethodLayout: PaymentSheet.PaymentMethodLayout { get }
    var shouldReadPaymentMethodOptionsSetupFutureUsage: Bool { get set }
}

extension PaymentElementConfiguration {

    /// Returns `true` if the merchant requires the collection of _any_ billing detail fields - name, phone, email, address.
    func requiresBillingDetailCollection() -> Bool {
        return billingDetailsCollectionConfiguration.name == .always
        || billingDetailsCollectionConfiguration.phone == .always
        || billingDetailsCollectionConfiguration.email == .always
        || billingDetailsCollectionConfiguration.address == .full
    }

    var fulfilledRequirements: [PaymentMethodTypeRequirement] {
        var reqs = [PaymentMethodTypeRequirement]()
        if returnURL != nil { reqs.append(.returnURL) }
        if allowsDelayedPaymentMethods { reqs.append(.userSupportsDelayedPaymentMethods) }
        if allowsPaymentMethodsRequiringShippingAddress { reqs.append(.shippingAddress) }
        if FinancialConnectionsSDKAvailability.isFinancialConnectionsSDKAvailable {
            reqs.append(.financialConnectionsSDK)
        }
        return reqs
    }

    /// Returns the effective `PaymentSheet.BillingDetails`, which refers to billing details that have been supplemented with billing information
    /// from the `linkAccount`. For instance, billing details with a missing email address can be supplemented with the Link account's email address.
    func effectiveBillingDetails(for linkAccount: PaymentSheetLinkAccount) -> PaymentSheet.BillingDetails {
        var billingDetails = defaultBillingDetails

        if billingDetailsCollectionConfiguration.email == .always {
            billingDetails.email = billingDetails.email ?? linkAccount.email
        }

        if billingDetailsCollectionConfiguration.phone == .always {
            billingDetails.phone = billingDetails.phone ?? linkAccount.currentSession?.unredactedPhoneNumberWithPrefix ?? linkAccount.phoneNumberUsedInSignup
        }

        if billingDetailsCollectionConfiguration.name == .always {
            // We can't get the name from the consumer session
            billingDetails.name = billingDetails.name ?? linkAccount.nameUsedInSignup
        }

        return billingDetails
    }
}

extension PaymentSheet.Configuration: PaymentElementConfiguration {}
extension EmbeddedPaymentElement.Configuration: PaymentElementConfiguration {
    var paymentMethodLayout: PaymentSheet.PaymentMethodLayout {
        return .vertical
    }
}
