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

        /// A URL that redirects back to your app that CustomerSheet can use to auto-dismiss
        /// web views used for additional authentication, e.g. 3DS2
        public var returnURL: String?

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = STPAPIClient.shared

        /// Whether to show Apple Pay as an option
        public var applePayEnabled: Bool = false

        /// Optional configuration for setting the header text of the Payment Method selection screen
        public var headerTextForSelectionScreen: String?

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
        /// A saved payment method was selected.
        case saved(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)
        /// A new payment method was saved and selected.
        case new(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)

        /// Create a PaymentOptionSelection for a saved payment method.
        public static func savedPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .saved(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }

        /// Create a PaymentOptionSelection for a new payment method.
        public static func newPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .new(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
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
            case .saved(_, let paymentOptionDisplayData):
                return paymentOptionDisplayData
            case .new(_, let paymentOptionDisplayData):
                return paymentOptionDisplayData
            }
        }

        func customerPaymentMethodOption() -> CustomerPaymentOption {
            switch self {
            case .applePay:
                return .applePay
            case .saved(let paymentMethod, _):
                return .stripeId(paymentMethod.stripeId)
            case .new(let paymentMethod, _):
                return .stripeId(paymentMethod.stripeId)
            }
        }
    }
}
