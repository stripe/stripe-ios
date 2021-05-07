//
//  PaymentSheetConfiguration.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

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

    /// Configuration for PaymentSheet
    public struct Configuration {
        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// Configuration related to Apple Pay
        /// If set, PaymentSheet displays Apple Pay as a payment option
        public var applePay: ApplePayConfiguration? = nil

        /// The amount of billing address details to collect
        /// Intentionally non-public.
        /// @see BillingAddressCollection
        var billingAddressCollectionLevel: BillingAddressCollectionLevel = .automatic

        /// The color of the Buy or Add button. Defaults to `.systemBlue`
        public var primaryButtonColor: UIColor = .systemBlue {
            didSet {
                ConfirmButton.BuyButton.appearance().backgroundColor = primaryButtonColor
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

        /// Initializes a ApplePayConfiguration
        public init(merchantId: String, merchantCountryCode: String) {
            self.merchantId = merchantId
            self.merchantCountryCode = merchantCountryCode
        }
    }
}
