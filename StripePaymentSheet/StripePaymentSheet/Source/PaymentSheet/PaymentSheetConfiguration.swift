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

    /// Style options for colors in PaymentSheet
    public enum UserInterfaceStyle: Int {

        /// (default) PaymentSheet will automatically switch between standard and dark mode compatible colors based on device settings
        case automatic = 0

        /// PaymentSheet will always use colors appropriate for standard, i.e. non-dark mode UI
        case alwaysLight

        /// PaymentSheet will always use colors appropriate for dark mode UI
        case alwaysDark

        func configure(_ viewController: UIViewController) {
            switch self {
            case .automatic:
                break  // no-op

            case .alwaysLight:
                viewController.overrideUserInterfaceStyle = .light

            case .alwaysDark:
                viewController.overrideUserInterfaceStyle = .dark
            }
        }
    }

    /// Options for the default state of save payment method controls
    /// @note Some jurisdictions may have rules governing the ability to default to opt-out behaviors
    public enum SavePaymentMethodOptInBehavior {

        /// (Default) The SDK will apply opt-out behavior for supported countries.
        /// Currently, we use requiresOptIn for all countries.
        case automatic

        /// The control will always default to unselected and users
        /// will have to explicitly interact to save their payment method
        case requiresOptIn

        /// The control will always default to selected and users
        /// will have to explicitly interact to not save their payment method
        case requiresOptOut

        var isSelectedByDefault: Bool {
            switch self {
            case .automatic:
                return false
            case .requiresOptIn:
                return false
            case .requiresOptOut:
                return true
            }
        }
    }

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

        /// Configuration related to Link
        public var link: LinkConfiguration = LinkConfiguration()

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
        public var externalPaymentMethodConfiguration: ExternalPaymentMethodConfiguration?

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

        /// If true, the payment method options setup future usage overrides the top-level setup future usage if set
        @_spi(PaymentMethodOptionsSetupFutureUsagePreview) public var shouldReadPaymentMethodOptionsSetupFutureUsage: Bool = false
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

    internal enum CustomerAccessProvider {
        case legacyCustomerEphemeralKey(String)
        case customerSession(String)

        var analyticValue: String {
            switch self {
            case .legacyCustomerEphemeralKey:
                return "legacy"
            case .customerSession:
                return "customer_session"
            }
        }
    }

    /// Configuration related to the Stripe Customer
    public struct CustomerConfiguration {
        /// The identifier of the Stripe Customer object.
        /// See https://stripe.com/docs/api/customers/object#customer_object-id
        public let id: String

        /// A short-lived token that allows the SDK to access a Customer's payment methods
        public let ephemeralKeySecret: String

        internal let customerAccessProvider: CustomerAccessProvider

        /// Initializes a CustomerConfiguration with an ephemeralKeySecret
        public init(id: String, ephemeralKeySecret: String) {
            self.id = id
            self.customerAccessProvider = .legacyCustomerEphemeralKey(ephemeralKeySecret)
            self.ephemeralKeySecret = ephemeralKeySecret
        }

        /// Initializes a CustomerConfiguration with a customerSessionClientSecret
        @_spi(CustomerSessionBetaAccess)
        public init(id: String, customerSessionClientSecret: String) {
            self.id = id
            self.customerAccessProvider = .customerSession(customerSessionClientSecret)
            self.ephemeralKeySecret = ""

            stpAssert(!customerSessionClientSecret.hasPrefix("ek_"),
                      "Argument looks like an Ephemeral Key secret, but expecting a CustomerSession client secret. See CustomerSession API: https://docs.stripe.com/api/customer_sessions/create")
            stpAssert(customerSessionClientSecret.hasPrefix("cuss_"),
                      "Argument does not look like a CustomerSession client secret. See CustomerSession API: https://docs.stripe.com/api/customer_sessions/create")
        }
    }

    /// Configuration related to Apple Pay
    public struct ApplePayConfiguration {
        /// The Apple Merchant Identifier to use during Apple Pay transactions.
        /// To obtain one, see https://stripe.com/docs/apple-pay#native
        public let merchantId: String

        /// The two-letter ISO 3166 code of the country of your business, e.g. "US"
        /// See your account's country value here https://dashboard.stripe.com/settings/account
        public let merchantCountryCode: String

        /// Defines the label that will be displayed in the Apple Pay button.
        /// See <https://developer.apple.com/design/human-interface-guidelines/technologies/apple-pay/buttons-and-marks/>
        /// for all available options.
        public let buttonType: PKPaymentButtonType

        /// An array of payment summary item objects that summarize the amount of the payment. This property is identical to `PKPaymentRequest.paymentSummaryItems`.
        /// If `nil`, we display a single line item with the amount on the PaymentIntent or "Amount pending" for SetupIntents.
        /// If you're using a SetupIntent for a recurring payment, you should set this to display the amount you intend to charge, in accordance with https://developer.apple.com/design/human-interface-guidelines/technologies/apple-pay/subscriptions-and-donations
        /// Follow Apple's documentation to set this property: https://developer.apple.com/documentation/passkit/pkpaymentrequest/1619231-paymentsummaryitems
        public let paymentSummaryItems: [PKPaymentSummaryItem]?

        /// Optional handler blocks for Apple Pay
        public let customHandlers: Handlers?

        /// Custom handler blocks for Apple Pay
        public struct Handlers {
            /// Optionally configure additional information on your PKPaymentRequest.
            /// This closure will be called after the PKPaymentRequest is created, but before the Apple Pay sheet is presented.
            /// In your implementation, you can configure the PKPaymentRequest to add custom fields, such as `recurringPaymentRequest`.
            /// See https://developer.apple.com/documentation/passkit/pkpaymentrequest for all configuration options.
            /// - Parameter: The PKPaymentRequest created by PaymentSheet.
            /// - Return: The PKPaymentRequest after your modifications.
            public let paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)?

            /// Optionally configure additional information on your PKPaymentAuthorizationResult.
            /// This closure will be called after the PaymentIntent or SetupIntent is confirmed, but before
            /// the Apple Pay sheet has been closed.
            /// In your implementation, you can configure the PKPaymentAuthorizationResult to add custom fields, such as `orderDetails`.
            /// See https://developer.apple.com/documentation/passkit/pkpaymentauthorizationresult for all configuration options.
            /// - Parameter $0: The PKPaymentAuthorizationResult created by PaymentSheet.
            /// - Parameter $1: A completion handler. You must call this handler with the PKPaymentAuthorizationResult on the main queue
            /// after applying your modifications.
            /// For example:
            /// ```
            /// .authorizationResultHandler = { result, completion in
            ///     result.orderDetails = PKPaymentOrderDetails(/* ... */)
            ///     completion(result)
            /// }
            /// ```
            /// WARNING: If you do not call the completion handler, your app will hang until the Apple Pay sheet times out.
            public let authorizationResultHandler:
            ((PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void)?

            /// Initializes the ApplePayConfiguration Handlers.
            public init(
                paymentRequestHandler: ((PKPaymentRequest) -> PKPaymentRequest)? = nil,
                authorizationResultHandler: (
                    (PKPaymentAuthorizationResult, @escaping ((PKPaymentAuthorizationResult) -> Void)) -> Void
                )? = nil
            ) {
                self.paymentRequestHandler = paymentRequestHandler
                self.authorizationResultHandler = authorizationResultHandler
            }
        }

        /// Initializes a ApplePayConfiguration
        public init(
            merchantId: String,
            merchantCountryCode: String,
            buttonType: PKPaymentButtonType = .plain,
            paymentSummaryItems: [PKPaymentSummaryItem]? = nil,
            customHandlers: Handlers? = nil
        ) {
            self.merchantId = merchantId
            self.merchantCountryCode = merchantCountryCode
            self.buttonType = buttonType
            self.paymentSummaryItems = paymentSummaryItems
            self.customHandlers = customHandlers
        }
    }

    /// Configuration related to Link
    public struct LinkConfiguration {
        /// The Link display mode.
        public var display: Display = .automatic

        /// Display configuration for Link
        public enum Display: String {
            /// Link will be displayed when available.
            case automatic
            /// Link will never be displayed.
            case never
        }

        var shouldDisplay: Bool {
            switch display {
            case .automatic: true
            case .never: false
            }
        }

        /// Initializes a LinkConfiguration
        public init(
            display: Display = .automatic
        ) {
            self.display = display
        }
    }

    /// An address.
    public struct Address: Equatable {
        /// City, district, suburb, town, or village.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var city: String?

        /// Two-letter country code (ISO 3166-1 alpha-2).
        public var country: String?

        /// Address line 1 (e.g., street, PO Box, or company name).
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var line1: String?

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var line2: String?

        /// ZIP or postal code.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var postalCode: String?

        /// State, county, province, or region.
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var state: String?

        /// Initializes an Address
        public init(
            city: String? = nil,
            country: String? = nil,
            line1: String? = nil,
            line2: String? = nil,
            postalCode: String? = nil,
            state: String? = nil
        ) {
            self.city = city
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.postalCode = postalCode
            self.state = state
        }
    }

    /// Billing details of a customer
    public struct BillingDetails: Equatable {
        /// The customer's billing address
        public var address: Address = Address()

        /// The customer's email
        /// - Note: When used with defaultBillingDetails, the value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var email: String?

        /// The customer's full name
        /// - Note: When used with defaultBillingDetails, the value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var name: String?

        /// The customer's phone number in e164 formatting (e.g. +15551234567)
        /// - Note: When used with defaultBillingDetails, omitting '+' will assume a US based phone number.
        public var phone: String?

        /// The customer's phone number formatted for display in your UI (e.g. "+1 (555) 555-5555")
        public var phoneNumberForDisplay: String? {
            guard let phone = self.phone else {
                return nil
            }
            return PhoneNumber.fromE164(phone)?.string(as: .international)
        }

        /// Initializes billing details
        public init(address: PaymentSheet.Address = Address(), email: String? = nil, name: String? = nil, phone: String? = nil) {
            self.address = address
            self.email = email
            self.name = name
            self.phone = phone
        }
    }

    /// Configuration for how billing details are collected during checkout.
    public struct BillingDetailsCollectionConfiguration: Equatable {
        /// Billing details fields collection options.
        public enum CollectionMode: String, CaseIterable {
            /// The field will be collected depending on the Payment Method's requirements.
            case automatic
            /// The field will never be collected.
            /// If this field is required by the Payment Method, you must provide it as part of `defaultBillingDetails`.
            case never
            /// The field will always be collected, even if it isn't required for the Payment Method.
            case always
        }

        /// Billing address collection options.
        public enum AddressCollectionMode: String, CaseIterable {
            /// Only the fields required by the Payment Method will be collected, this may be none.
            case automatic
            /// Address will never be collected.
            /// If the Payment Method requires a billing address, you must provide it as part of
            /// `defaultBillingDetails`.
            case never
            /// Collect the full billing address, regardless of the Payment Method requirements.
            case full
        }

        /// How to collect the name field.
        /// Defaults to `automatic`.
        public var name: CollectionMode = .automatic

        /// How to collect the phone field.
        /// Defaults to `automatic`.
        public var phone: CollectionMode = .automatic

        /// How to collect the email field.
        /// Defaults to `automatic`.
        public var email: CollectionMode = .automatic

        /// How to collect the billing address.
        /// Defaults to `automatic`.
        public var address: AddressCollectionMode = .automatic

        /// Whether the values included in `Configuration.defaultBillingDetails` should be attached to the payment
        /// method, this includes fields that aren't displayed in the form.
        ///
        /// If `false` (the default), those values will only be used to prefill the corresponding fields in the form.
        public var attachDefaultsToPaymentMethod = false
    }

    /// Configuration for external payment methods
    /// - Seealso: See the [integration guide](https://stripe.com/docs/payments/external-payment-methods?platform=ios).
    public struct ExternalPaymentMethodConfiguration {

        /// Initializes an `ExternalPaymentMethodConfiguration`
        /// - Parameter externalPaymentMethods: A list of external payment methods to display in PaymentSheet e.g., ["external_paypal"].
        /// - Parameter externalPaymentMethodConfirmHandler: A handler called when the customer confirms the payment using an external payment method.
        /// - Seealso: See the [integration guide](https://stripe.com/docs/payments/external-payment-methods?platform=ios).
        public init(externalPaymentMethods: [String], externalPaymentMethodConfirmHandler: @escaping PaymentSheet.ExternalPaymentMethodConfiguration.ExternalPaymentMethodConfirmHandler) {
            self.externalPaymentMethods = externalPaymentMethods
            self.externalPaymentMethodConfirmHandler = externalPaymentMethodConfirmHandler
        }

        /// A list of external payment methods to display in PaymentSheet.
        /// e.g. ["external_paypal"].
        public var externalPaymentMethods: [String] = []

        /// - Parameter externalPaymentMethodType: The external payment method to confirm payment with e.g., "external_paypal"
        /// - Parameter billingDetails: An object containing any billing details you've configured PaymentSheet to collect.
        /// - Parameter completion: Call this after payment has completed, passing the result of the payment.
        /// - Returns: The result of the attempt to confirm payment using the given external payment method.
        public typealias ExternalPaymentMethodConfirmHandler = (
            _ externalPaymentMethodType: String,
            _ billingDetails: STPPaymentMethodBillingDetails,
            _ completion: @escaping ((PaymentSheetResult) -> Void)
        ) -> Void

        /// This handler is called when the customer confirms the payment using an external payment method.
        /// Your implementation should complete the payment and call the `completion` parameter with the result.
        /// - Note: This is always called on the main thread.
        public var externalPaymentMethodConfirmHandler: ExternalPaymentMethodConfirmHandler
    }

    /// Configuration for custom payment methods
    @_spi(CustomPaymentMethodsBeta) public struct CustomPaymentMethodConfiguration {

        /// Defines a custom payment method type that can be displayed in PaymentSheet
        public struct CustomPaymentMethod {

            /// The unique identifier for this custom payment method type in the format of "cpmt_..."
            /// Obtained from the Stripe Dashboard at https://dashboard.stripe.com/settings/custom_payment_methods
            public let id: String

            /// Optional subtitle text to be displayed below the custom payment method's display name.
            public let subtitle: String?

            /// When false, PaymentSheet will collect billing details for this custom payment method type
            /// in accordance with the `billingDetailsCollectionConfiguration` settings.
            /// This has no effect if `billingDetailsCollectionConfiguration` is not configured.
            public var disableBillingDetailCollection = true

            /// Initializes an `CustomPaymentMethod`
            /// - Parameters:
            ///   - id: The unique identifier for this custom payment method type in the format of "cpmt_..."
            ///   - subtitle: Optional subtitle text to be displayed below the custom payment method's display name.
            public init(id: String, subtitle: String? = nil) {
                self.id = id
                self.subtitle = subtitle
            }
        }

        /// Initializes an `CustomPaymentMethodConfiguration`
        /// - Parameter customPaymentMethods: A list of custom payment methods to display in PaymentSheet.
        /// - Parameter customPaymentMethodConfirmHandler: A handler called when the customer confirms the payment using a custom payment method.
        public init(customPaymentMethods: [CustomPaymentMethod], customPaymentMethodConfirmHandler: @escaping PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodConfirmHandler) {
            self.customPaymentMethods = customPaymentMethods
            self.customPaymentMethodConfirmHandler = customPaymentMethodConfirmHandler
        }

        /// A list of custom payment methods types to display in PaymentSheet.
        public var customPaymentMethods: [CustomPaymentMethod] = []

        /// - Parameter customPaymentMethod: The custom payment method to confirm payment with
        /// - Parameter billingDetails: An object containing any billing details you've configured PaymentSheet to collect.
        /// - Returns: The result of the attempt to confirm payment using the given custom payment method.
        public typealias CustomPaymentMethodConfirmHandler = (
            _ customPaymentMethod: CustomPaymentMethod,
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

extension PaymentSheet {
    /// Options to block certain card brands on the client
    public enum CardBrandAcceptance: Equatable {

        /// Card brand categories that can be allowed or disallowed
        public enum BrandCategory: Equatable  {
            /// Visa branded cards
            case visa
            /// Mastercard branded cards
            case mastercard
            /// Amex branded cards
            case amex
            /// Discover branded cards.
            /// - Note: Encompasses all of Discover Global Network (Discover, Diners, JCB, UnionPay, Elo)
            case discover
        }

        /// Accept all card brands supported by Stripe
        case all
        /// Accept only the card brands specified in the associated value
        /// - Note: Any card brands that do not map to a `BrandCategory` will be blocked when using an allow list.
        case allowed(brands: [BrandCategory])
        /// Accept all card brands supported by Stripe except for those specified in the associated value
        /// - Note: Any card brands that do not map to a `BrandCategory` will be accepted when using a disallow list.
        case disallowed(brands: [BrandCategory])
    }
}
