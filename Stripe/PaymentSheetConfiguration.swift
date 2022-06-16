//
//  PaymentSheetConfiguration.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import PassKit
@_spi(STP) import StripeCore

// MARK: - Configuration
extension PaymentSheet {

    /// Billing address collection modes for PaymentSheet
    enum BillingAddressCollectionLevel {
        /// (Default) PaymentSheet will only collect the necessary billing address information
        case automatic

        /// PaymentSheet will always collect full billing address details
        case required
    }

    /// Style options for colors in PaymentSheet
    @available(iOS 13.0, *)
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
        /// Currently, this behavior is supported in the US.
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
                // only enable the save checkbox by default for US
                return Locale.current.regionCode == "US"
            case .requiresOptIn:
                return false
            case .requiresOptOut:
                return true
            }
        }
    }

    /// Configuration for PaymentSheet
    public struct Configuration {
        
        /// If true, allows payment methods that do not move money at the end of the checkout. Defaults to false.
        /// - Description: Some payment methods can't guarantee you will receive funds from your customer at the end of the checkout because they take time to settle (eg. most bank debits, like SEPA or ACH) or require customer action to complete (e.g. OXXO, Konbini, Boleto). If this is set to true, make sure your integration listens to webhooks for notifications on whether a payment has succeeded or not.
        /// - Seealso: https://stripe.com/docs/payments/payment-methods#payment-notification
        public var allowsDelayedPaymentMethods: Bool = false
        
        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// Configuration related to Apple Pay
        /// If set, PaymentSheet displays Apple Pay as a payment option
        public var applePay: ApplePayConfiguration? = nil

        /// The amount of billing address details to collect
        /// Intentionally non-public.
        /// @see BillingAddressCollection
        var billingAddressCollectionLevel: BillingAddressCollectionLevel = .automatic

        /// The color of the Buy or Add button. Defaults to `.systemBlue` when `nil`.
        public var primaryButtonColor: UIColor? {
            set {
                appearance.primaryButton.backgroundColor = newValue
            }
            
            get {
                return appearance.primaryButton.backgroundColor
            }
        }

        private var styleRawValue: Int = 0  // SheetStyle.automatic.rawValue
        /// The color styling to use for PaymentSheet UI
        /// Default value is SheetStyle.automatic
        /// @see SheetStyle
        @available(iOS 13.0, *)
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
        public var customer: CustomerConfiguration? = nil

        /// Your customer-facing business name.
        /// This is used to display a "Pay \(merchantDisplayName)" line item in the Apple Pay sheet
        /// The default value is the name of your app, using CFBundleDisplayName or CFBundleName
        public var merchantDisplayName: String = Bundle.displayName ?? ""

        /// A URL that redirects back to your app that PaymentSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String? = nil

        /// PaymentSheet pre-populates fields with the values provided.
        public var defaultBillingDetails: BillingDetails = BillingDetails()
        
        /// PaymentSheet offers users an option to save some payment methods for later use.
        /// Default value is .automatic
        /// @see SavePaymentMethodOptInBehavior
        public var savePaymentMethodOptInBehavior: SavePaymentMethodOptInBehavior = .automatic
        
        internal var linkPaymentMethodsOnly: Bool = false
        
        /// Describes the appearance of PaymentSheet
        public var appearance = PaymentSheet.Appearance.default
        
        /// 🏗 Under construction
        /// Configuration related to shipping address collection
        @_spi(STP) public var shippingAddress: ShippingAddressConfiguration = .init()
        
        /// Initializes a Configuration with default values
        public init() {}
    }

    /// Configuration related to the Stripe Customer
    public struct CustomerConfiguration {
        /// The identifier of the Stripe Customer object.
        /// See https://stripe.com/docs/api/customers/object#customer_object-id
        public let id: String

        /// A short-lived token that allows the SDK to access a Customer's payment methods
        public let ephemeralKeySecret: String

        /// Initializes a CustomerConfiguration
        public init(id: String, ephemeralKeySecret: String) {
            self.id = id
            self.ephemeralKeySecret = ephemeralKeySecret
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
        
        /// An array of payment summary item objects that summarize the amount of the payment. This property is identical to `PKPaymentRequest.paymentSummaryItems`.
        /// If `nil`, we display a single line item with the amount on the PaymentIntent or "Amount pending" for SetupIntents.
        /// If you're using a SetupIntent for a recurring payment, you should set this to display the amount you intend to charge, in accordance with https://developer.apple.com/design/human-interface-guidelines/technologies/apple-pay/subscriptions-and-donations
        /// Follow Apple's documentation to set this property: https://developer.apple.com/documentation/passkit/pkpaymentrequest/1619231-paymentsummaryitems
        public let paymentSummaryItems: [PKPaymentSummaryItem]?

        /// Initializes a ApplePayConfiguration
        public init(merchantId: String, merchantCountryCode: String, paymentSummaryItems: [PKPaymentSummaryItem]? = nil) {
            self.merchantId = merchantId
            self.merchantCountryCode = merchantCountryCode
            self.paymentSummaryItems = paymentSummaryItems
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
        public init(city: String? = nil, country: String? = nil, line1: String? = nil, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
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
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var email: String?
        
        /// The customer's full name
        /// - Note: The value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var name: String?
        
        /// The customer's phone number without formatting (e.g. 5551234567)
        public var phone: String?
    }
}
