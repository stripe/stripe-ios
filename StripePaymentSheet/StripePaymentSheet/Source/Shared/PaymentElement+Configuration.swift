//
//  PaymentElementConfiguration.swift
//  StripePaymentSheet
//
//  Created by David Estes on 3/10/25.
//

@_spi(STP) import StripeCore
import PassKit

extension PaymentElement {
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
        public init(externalPaymentMethods: [String], externalPaymentMethodConfirmHandler: @escaping PaymentElement.ExternalPaymentMethodConfiguration.ExternalPaymentMethodConfirmHandler) {
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
