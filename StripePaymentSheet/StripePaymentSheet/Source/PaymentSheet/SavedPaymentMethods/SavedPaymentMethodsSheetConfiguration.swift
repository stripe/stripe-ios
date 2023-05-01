//
//  SavedPaymentMethodsSheetConfiguration.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension SavedPaymentMethodsSheet {

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

        /// A URL that redirects back to your app that PaymentSheet can use to auto-dismiss
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

extension SavedPaymentMethodsSheet {
    public enum PaymentOptionSelection {

        public struct PaymentOptionDisplayData {
            public let image: UIImage
            public let label: String
        }
        case applePay(paymentOptionDisplayData: PaymentOptionDisplayData)
        case saved(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)
        case new(paymentMethod: STPPaymentMethod, paymentOptionDisplayData: PaymentOptionDisplayData)

        public static func savedPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .saved(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }
        public static func newPaymentMethod(_ paymentMethod: STPPaymentMethod) -> PaymentOptionSelection {
            let data = PaymentOptionDisplayData(image: paymentMethod.makeIcon(), label: paymentMethod.paymentSheetLabel)
            return .new(paymentMethod: paymentMethod, paymentOptionDisplayData: data)
        }
        public static func applePay() -> PaymentOptionSelection {
            let displayData = SavedPaymentMethodsSheet.PaymentOptionSelection.PaymentOptionDisplayData(image: Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal),
                                                                                                       label: String.Localized.apple_pay)
            return .applePay(paymentOptionDisplayData: displayData)
        }

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

        func persistablePaymentMethodOption() -> PersistablePaymentMethodOption {
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
