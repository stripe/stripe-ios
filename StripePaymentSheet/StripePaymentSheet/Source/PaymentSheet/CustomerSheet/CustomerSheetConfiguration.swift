//
//  CustomerSheetConfiguration.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension CustomerSheet {

    public struct Configuration {
        private var styleRawValue: Int = 0  // SheetStyle.automatic.rawValue
        /// The color styling to use for PaymentSheet UI
        /// Default value is SheetStyle.automatic
        /// @see SheetStyle
        public var style: PaymentSheet.UserInterfaceStyle {
            get {
                return PaymentSheet.UserInterfaceStyle(rawValue: styleRawValue)!
            }
            set {
                styleRawValue = newValue.rawValue
            }
        }
        /// Describes the appearance of SavdPaymentMethodsSheet
        public var appearance = PaymentSheet.Appearance.default

        /// Your customer-facing business name.
        /// This is used to display a "Pay \(merchantDisplayName)" line item in the Apple Pay sheet
        /// The default value is the name of your app, using CFBundleDisplayName or CFBundleName
        public var merchantDisplayName: String = Bundle.displayName ?? ""

        /// A URL that redirects back to your app that CustomerSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String?

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// Whether to show Apple Pay as an option
        public var applePayEnabled: Bool = false

        /// Optional configuration for setting the header text of the Payment Method selection screen
        public var headerTextForSelectionScreen: String?

        /// CustomerSheet pre-populates fields with the values provided.
        /// If `billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod` is `true`, these values will
        /// be attached to the payment method even if they are not collected by the CustomerSheet UI.
        public var defaultBillingDetails: PaymentSheet.BillingDetails = PaymentSheet.BillingDetails()

        /// Describes how billing details should be collected.
        /// All values default to `automatic`.
        /// If `never` is used for a required field for the Payment Method used during checkout,
        /// you **must** provide an appropriate value as part of `defaultBillingDetails`.
        public var billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration()

        /// Optional configuration to display a custom message when a saved payment method is removed.
        public var removeSavedPaymentMethodMessage: String?

        public init () {
        }
    }
}

extension CustomerSheet {
    /// A selected payment method from a CustomerSheet.
    public enum PaymentOptionSelection {
        /// Display data for a payment method option.
        public struct PaymentOptionDisplayData {
            /// An image to display to the user.
            public let image: UIImage
            /// A label to display to the user.
            public let label: String
        }
        /// Apple Pay is the selected payment option.
        case applePay(paymentOptionDisplayData: PaymentOptionDisplayData)
        /// A Stripe payment method was selected
        case paymentMethod(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)

        /// Create a PaymentOptionSelection for a saved payment method.
        public static func paymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .paymentMethod(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }

        /// Create a PaymentOptionSelection for Apple Pay.
        public static func applePay() -> PaymentOptionSelection {
            let displayData = CustomerSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal),
                                                                                                       label: String.Localized.apple_pay)
            return .applePay(paymentOptionDisplayData: displayData)
        }

        /// Returns a PaymentOptionDisplayData to display to the user.
        public func displayData() -> PaymentOptionDisplayData {
            switch self {
            case .applePay(let paymentOptionDisplayData):
                return paymentOptionDisplayData
            case .paymentMethod(_, let paymentOptionDisplayData):
                return paymentOptionDisplayData
            }
        }

        func customerPaymentMethodOption() -> CustomerPaymentOption {
            switch self {
            case .applePay:
                return .applePay
            case .paymentMethod(let paymentMethod, _):
                return .stripeId(paymentMethod.stripeId)
            }
        }
    }
}
