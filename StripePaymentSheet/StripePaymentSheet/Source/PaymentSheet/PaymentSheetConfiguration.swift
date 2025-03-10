//
//  PaymentSheetConfiguration.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// MARK: - Configuration

extension PaymentSheet {
    public typealias UserInterfaceStyle = StripePaymentSheet.UserInterfaceStyle
    public typealias SavePaymentMethodOptInBehavior = PaymentElement.SavePaymentMethodOptInBehavior

    /// Configuration for PaymentSheet
    public struct Configuration {
        // The text that shows in the header of the payment sheet when adding a card.
        // If nil default text will be used.
        @_spi(DashboardOnly) public var addCardHeaderText: String?

        /// If true, allows payment methods that do not move money at the end of the checkout. Defaults to false.
        /// - Description: Some payment methods can't guarantee you will receive funds from your customer at the end of the checkout because they take time to settle (eg. most bank debits, like SEPA or ACH) or require customer action to complete (e.g. OXXO, Konbini, Boleto). If this is set to true, make sure your integration listens to webhooks for notifications on whether a payment has succeeded or not.
        /// - Seealso: https://stripe.com/docs/payments/payment-methods#payment-notification
        public var allowsDelayedPaymentMethods: Bool = false

        /// If `true`, allows payment methods that require a shipping address, like Afterpay and Affirm. Defaults to `false`.
        /// Set this to `true` if you collect shipping addresses and set `Configuration.shippingDetails` or set `shipping` details directly on the PaymentIntent.
        /// - Note: PaymentSheet considers this property `true` and allows payment methods that require a shipping address if `shipping` details are present on the PaymentIntent when PaymentSheet loads.
        public var allowsPaymentMethodsRequiringShippingAddress: Bool = false

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// Configuration related to Apple Pay
        /// If set, PaymentSheet displays Apple Pay as a payment option
        public var applePay: ApplePayConfiguration?

        /// The color of the Buy or Add button. Defaults to `.systemBlue` when `nil`.
        public var primaryButtonColor: UIColor? {
            get {
                return appearance.primaryButton.backgroundColor
            }

            set {
                appearance.primaryButton.backgroundColor = newValue
            }
        }

        /// The label to use for the primary button.
        ///
        /// If not set, Payment Sheet will display suitable default labels
        /// for payment and setup intents.
        public var primaryButtonLabel: String?

        private var styleRawValue: Int = 0  // SheetStyle.automatic.rawValue
        /// The color styling to use for PaymentSheet UI
        /// Default value is SheetStyle.automatic
        /// @see SheetStyle
        public var style: UserInterfaceStyle {  // stored properties can't be marked @available which is why this uses the styleRawValue private var
            get {
                return UserInterfaceStyle(rawValue: styleRawValue)!
            }
            set {
                styleRawValue = newValue.rawValue
            }
        }

        /// Configuration related to the Stripe Customer
        /// If set, the customer can select a previously saved payment method within PaymentSheet
        public var customer: CustomerConfiguration?

        /// Your customer-facing business name.
        /// The default value is the name of your app, using CFBundleDisplayName or CFBundleName
        public var merchantDisplayName: String = Bundle.displayName ?? ""

        /// A URL that redirects back to your app that PaymentSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String?

        /// PaymentSheet pre-populates fields with the values provided.
        /// If `billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod` is `true`, these values will
        /// be attached to the payment method even if they are not collected by the PaymentSheet UI.
        public var defaultBillingDetails: BillingDetails = BillingDetails()

        /// PaymentSheet offers users an option to save some payment methods for later use.
        /// Default value is .automatic
        /// @see SavePaymentMethodOptInBehavior
        public var savePaymentMethodOptInBehavior: SavePaymentMethodOptInBehavior = .automatic

        /// Describes the appearance of PaymentSheet
        public var appearance = PaymentSheet.Appearance.default

        /// A closure that returns the customer's shipping details.
        /// This is used to display a "Billing address is same as shipping" checkbox if `defaultBillingDetails` is not provided
        /// If `name` and `line1` are populated, it's also [attached to the PaymentIntent](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-shipping) during payment.
        public var shippingDetails: () -> AddressViewController.AddressDetails? = { return nil }

        /// The list of preferred networks that should be used to process payments made with a co-branded card.
        /// This value will only be used if your user hasn't selected a network themselves.
        public var preferredNetworks: [STPCardBrand]? {
            didSet {
                guard let preferredNetworks = preferredNetworks else { return }
                assert(Set<STPCardBrand>(preferredNetworks).count == preferredNetworks.count,
                       "preferredNetworks must not contain any duplicate card brands")
            }
        }

        /// Controls whether to filter out wallet payment methods from the saved payment method list.
        @_spi(DashboardOnly) public var disableWalletPaymentMethodFiltering: Bool = false

        /// Initializes a Configuration with default values
        public init() {}

        /// Override country for test purposes
        @_spi(STP) public var userOverrideCountry: String?

        /// Describes how billing details should be collected.
        /// All values default to `automatic`.
        /// If `never` is used for a required field for the Payment Method used during checkout,
        /// you **must** provide an appropriate value as part of `defaultBillingDetails`.
        public var billingDetailsCollectionConfiguration = BillingDetailsCollectionConfiguration()

        /// Optional configuration to display a custom message when a saved payment method is removed.
        public var removeSavedPaymentMethodMessage: String?

        /// Configuration for external payment methods.
        public var externalPaymentMethodConfiguration: PaymentElement.ExternalPaymentMethodConfiguration?

        /// Configuration for custom payment methods.
        @_spi(CustomPaymentMethodsBeta) public var customPaymentMethodConfiguration: CustomPaymentMethodConfiguration?

        /// By default, PaymentSheet will use a dynamic ordering that optimizes payment method display for the customer.
        /// You can override the default order in which payment methods are displayed in PaymentSheet with a list of payment method types.
        /// See https://stripe.com/docs/api/payment_methods/object#payment_method_object-type for the list of valid types.  You may also pass external payment methods.
        /// - Example: ["card", "external_paypal", "klarna"]
        /// - Note: If you omit payment methods from this list, they’ll be automatically ordered by Stripe after the ones you provide. Invalid payment methods are ignored.
        public var paymentMethodOrder: [String]?

        // MARK: Internal
        // PaymentSheet components are only being used for Link.
        internal var linkPaymentMethodsOnly: Bool = false

        /// This is an experimental feature that may be removed at any time.
        /// If true (the default), the customer can delete all saved payment methods.
        /// If false, the customer can't delete if they only have one saved payment method remaining.
        @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) public var allowsRemovalOfLastSavedPaymentMethod = true

        /// The layout of payment methods in PaymentSheet. Defaults to `.automatic`.
        /// - Seealso: `PaymentSheet.PaymentMethodLayout` for the list of available layouts.
        public var paymentMethodLayout: PaymentMethodLayout = .automatic

        /// By default, PaymentSheet will accept all supported cards by Stripe.
        /// You can specify card brands PaymentSheet should block disallow or allow payment for by providing an array of those card brands.
        /// Note: For Apple Pay, the list of supported card brands is determined by combining `StripeAPI.supportedPKPaymentNetworks()` with `StripeAPI.additionalEnabledApplePayNetworks` and then applying the `cardBrandAcceptance` filter. This filtered list is then assigned to `PKPaymentRequest.supportedNetworks`, ensuring that only the allowed card brands are available for Apple Pay transactions. Any `PKPaymentNetwork` that does not correspond to a `BrandCategory` will be blocked if you have specified an allow list, or will not be blocked if you have specified a disallow list.
        /// Note: This is only a client-side solution.
        /// Note: Card brand filtering is not currently supported by Link.
        public var cardBrandAcceptance: PaymentSheet.CardBrandAcceptance = .all

        /// Flag used to stage the development of updating payment method
        @_spi(UpdatePaymentMethodBeta) public var updatePaymentMethodEnabled: Bool = false
    }

    /// Defines the layout orientations available for displaying payment methods in PaymentSheet.
    public enum PaymentMethodLayout {
        /// Payment methods are arranged horizontally. Users can swipe left or right to navigate through different payment methods.
        case horizontal

        /// Payment methods are arranged vertically. Users can scroll up or down to navigate through different payment methods.
        case vertical

        /// Stripe automatically chooses between `horizontal` and `vertical`.
        case automatic
    }

    public typealias ApplePayConfiguration = PaymentElement.ApplePayConfiguration
    public typealias CustomerConfiguration = PaymentElement.CustomerConfiguration
    public typealias CardBrandAcceptance = PaymentElement.CardBrandAcceptance
    public typealias BillingDetailsCollectionConfiguration = PaymentElement.BillingDetailsCollectionConfiguration
    public typealias ExternalPaymentMethodConfiguration = PaymentElement.ExternalPaymentMethodConfiguration

    public typealias Address = StripePaymentSheet.Address
    public typealias BillingDetails = StripePaymentSheet.BillingDetails

    /// Configuration for custom payment methods
    @_spi(CustomPaymentMethodsBeta) public struct CustomPaymentMethodConfiguration {

        /// Defines a custom payment method type that can be displayed in PaymentSheet
        public struct CustomPaymentMethodType {

            /// The unique identifier for this custom payment method type in the format of "cmpt_..."
            /// Obtained from the Stripe Dashboard at https://dashboard.stripe.com/settings/custom_payment_methods
            public let id: String

            /// Optional subcopy text to be displayed below the custom payment method's display name.
            public let subcopy: String?

            /// When true, PaymentSheet will collect billing details for this custom payment method type
            /// in accordance with the `billingDetailsCollectionConfiguration` settings.
            /// This has no effect if `billingDetailsCollectionConfiguration` is not configured.
            public var shouldCollectBillingDetails = false

            /// Initializes an `CustomPaymentMethodType`
            /// - Parameters:
            ///   - id: The unique identifier for this custom payment method type in the format of "cmpt_..."
            ///   - subcopy: Optional subcopy text to be displayed below the custom payment method's display name.
            public init(id: String, subcopy: String? = nil) {
                self.id = id
                self.subcopy = subcopy
            }
        }

        /// Initializes an `CustomPaymentMethodConfiguration`
        /// - Parameter customPaymentMethodTypes: A list of custom payment methods to display in PaymentSheet.
        /// - Parameter customPaymentMethodConfirmHandler: A handler called when the customer confirms the payment using a custom payment method.
        public init(customPaymentMethodTypes: [CustomPaymentMethodType], customPaymentMethodConfirmHandler: @escaping PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodConfirmHandler) {
            self.customPaymentMethodTypes = customPaymentMethodTypes
            self.customPaymentMethodConfirmHandler = customPaymentMethodConfirmHandler
        }

        /// A list of custom payment methods types to display in PaymentSheet.
        public var customPaymentMethodTypes: [CustomPaymentMethodType] = []

        /// - Parameter customPaymentMethodType: The custom payment method to confirm payment with
        /// - Parameter billingDetails: An object containing any billing details you've configured PaymentSheet to collect.
        /// - Returns: The result of the attempt to confirm payment using the given custom payment method.
        public typealias CustomPaymentMethodConfirmHandler = (
            _ customPaymentMethodType: CustomPaymentMethodType,
            _ billingDetails: STPPaymentMethodBillingDetails
        ) async -> PaymentSheetResult

        /// This handler is called when the customer confirms the payment using an custom payment method.
        /// Your implementation should complete the payment and return the result.
        /// - Note: This is always called on the main thread.
        public var customPaymentMethodConfirmHandler: CustomPaymentMethodConfirmHandler
    }
}

extension STPPaymentMethodBillingDetails {
    func toPaymentSheetBillingDetails() -> PaymentSheet.BillingDetails {
        let address = PaymentSheet.Address(city: self.address?.city,
                                           country: self.address?.country,
                                           line1: self.address?.line1,
                                           line2: self.address?.line2,
                                           postalCode: self.address?.postalCode,
                                           state: self.address?.state)
        return PaymentSheet.BillingDetails(address: address,
                                           email: self.email,
                                           name: self.name,
                                           phone: self.phone)
    }
}
extension PaymentSheet.CustomerConfiguration {
    func ephemeralKeySecretBasedOn(elementsSession: STPElementsSession?) -> String? {
        switch customerAccessProvider {
        case .legacyCustomerEphemeralKey(let legacy):
            return legacy
        case .customerSession:
            return elementsSession?.customer?.customerSession.apiKey
        }
    }
}
