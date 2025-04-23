//
//  EmbeddedPaymentElementConfiguration.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/25/24.
//

@_spi(STP) import StripeCore
import UIKit

extension EmbeddedPaymentElement {
    public struct Configuration {
        /// If true, allows payment methods that do not move money at the end of the checkout. Defaults to false.
        /// - Description: Some payment methods can't guarantee you will receive funds from your customer at the end of the checkout because they take time to settle (eg. most bank debits, like SEPA or ACH) or require customer action to complete (e.g. OXXO, Konbini, Boleto). If this is set to true, make sure your integration listens to webhooks for notifications on whether a payment has succeeded or not.
        /// - Seealso: https://stripe.com/docs/payments/payment-methods#payment-notification
        public var allowsDelayedPaymentMethods: Bool = false

        /// If `true`, allows payment methods that require a shipping address, like  Affirm. Defaults to `false`.
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

        /// This is an experimental feature that may be removed at any time.
        /// If true (the default), the customer can delete all saved payment methods.
        /// If false, the customer can't delete if they only have one saved payment method remaining.
        @_spi(ExperimentalAllowsRemovalOfLastSavedPaymentMethodAPI) public var allowsRemovalOfLastSavedPaymentMethod = true

        /// By default, the embedded payment element will accept all supported cards by Stripe.
        /// You can specify card brands the embedded payment element should block disallow or allow payment for by providing an array of those card brands.
        /// Note: For Apple Pay, the list of supported card brands is determined by combining `StripeAPI.supportedPKPaymentNetworks()` with `StripeAPI.additionalEnabledApplePayNetworks` and then applying the `cardBrandAcceptance` filter. This filtered list is then assigned to `PKPaymentRequest.supportedNetworks`, ensuring that only the allowed card brands are available for Apple Pay transactions. Any `PKPaymentNetwork` that does not correspond to a `BrandCategory` will be blocked if you have specified an allow list, or will not be blocked if you have specified a disallow list.
        /// Note: This is only a client-side solution.
        /// Note: Card brand filtering is not currently supported by Link.
        public var cardBrandAcceptance: PaymentSheet.CardBrandAcceptance = .all

        /// If true, the payment method options setup future usage overrides the top-level setup future usage if set
        @_spi(PaymentMethodOptionsSetupFutureUsagePreview) public var shouldReadPaymentMethodOptionsSetupFutureUsage: Bool = false

        /// The view can display payment methods like “Card” that, when tapped, open a form sheet where customers enter their payment method details. The sheet has a button at the bottom. `FormSheetAction` enumerates the actions the button can perform.
        public enum FormSheetAction {
            /// The button says “Pay” or “Setup”. When tapped, we confirm the payment or setup in the form sheet.
            /// - Parameter completion: Called with the result of the payment or setup.
            case confirm(
                completion: (EmbeddedPaymentElementResult) -> Void
            )

            /// The button says “Continue”. When tapped, the form sheet closes. The customer can confirm payment or setup back in your app.
            case `continue`
        }

        /// The view can display payment methods like “Card” that, when tapped, open a sheet where customers enter their payment method details. The sheet has a button at the bottom. `formSheetAction` controls the action the button performs.
        public var formSheetAction: FormSheetAction = .continue

        /// Controls whether the view displays mandate text at the bottom for payment methods that require it. If set to `false`, your integration must display `PaymentOptionDisplayData.mandateText` to the customer near your “Buy” button to comply with regulations.
        /// - Note: This doesn't affect mandates displayed in the form sheet.
        public var embeddedViewDisplaysMandateText: Bool = true

        /// Controls whether to filter out wallet payment methods from the saved payment method list.
        @_spi(DashboardOnly) public var disableWalletPaymentMethodFiltering: Bool = false

        internal var linkPaymentMethodsOnly: Bool = false

        /// Describes how you handle row selections in EmbeddedPaymentElement
        public enum RowSelectionBehavior {
          /// When a payment option is selected, the customer taps a button to continue or confirm payment.
          /// This is the default recommended integration.
          case `default`

          /// When a payment option is selected, `didSelectPaymentOption` is triggered.
          /// You can implement this method to immediately perform an action e.g. go back to the checkout screen or confirm the payment.
          /// Note that certain payment options like Apple Pay and saved payment methods are disabled in this mode if you set `formSheetAction` to `.confirm`.
          case immediateAction(didSelectPaymentOption: () -> Void)
        }

        /// Determines the behavior when a row  is selected. Defaults to `.default`.
        public var rowSelectionBehavior: RowSelectionBehavior = .default

        /// Initializes a Configuration with default values
        public init() {}
    }
}
