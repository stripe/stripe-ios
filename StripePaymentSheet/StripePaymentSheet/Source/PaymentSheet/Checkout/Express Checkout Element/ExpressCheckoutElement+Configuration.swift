//
//  ExpressCheckoutElement+Configuration.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit

@_spi(STP)
@_spi(ReactNativeSDK)
extension ExpressCheckoutElement {
    /// Configuration options for ``ExpressCheckoutElement``.
    public struct Configuration {
        /// Whether to require collecting a shipping address. Default: `false`.
        public var shippingAddressRequired: Bool = false
        /// Configuration for collecting billing details.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()
        /// Sets the configuration for Apple Pay.
        public var applePayConfiguration: ApplePayConfiguration?
        /// Sets the configuration for Link.
        public var linkConfiguration: LinkConfiguration = .init()

        /// Overrides display order of payment methods. nil uses default dynamic ordering.
        public var paymentMethodOrder: [ExpressCheckoutElement.PaymentMethod]?
        /// Controls appearance of Express Checkout Element.
        public var appearance: Appearance = .init()

        /// Creates an Express Checkout Element configuration with default values.
        public init() {}
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

        public init(
            name: CollectionMode = .automatic,
            phone: CollectionMode = .automatic,
            email: CollectionMode = .automatic,
            address: AddressCollectionMode = .automatic
        ) {
            self.name = name
            self.phone = phone
            self.email = email
            self.address = address
        }
    }

    /// Configuration for Link.
    public struct LinkConfiguration {
        /// Controls whether Link is displayed.
        public enum Display: String {
            /// Show Link when it is available.
            case automatic
            /// Never show Link.
            case never
        }

        /// Controls whether Link is displayed.
        public var display: Display = .automatic

        /// Whether missing billing details should be collected for existing Link payment methods.
        @_spi(CollectMissingLinkBillingDetailsPreview) public var collectMissingBillingDetailsForExistingPaymentMethods: Bool = true

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }
    }

    /// Configuration for Apple Pay.
    public struct ApplePayConfiguration {
        /// The Apple Pay merchant identifier.
        public let merchantId: String

        /// The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        public var buttonType: PKPaymentButtonType?

        /// Controls whether Apple Pay is displayed.
        public var display: Display = .automatic

        /// Controls whether Apple Pay is displayed.
        public enum Display: String {
            /// Show Apple Pay when it is available.
            case automatic
            /// Never show Apple Pay.
            case never
        }

        /// Creates an Apple Pay configuration.
        /// - Parameters:
        ///   - merchantId: The Apple Pay merchant identifier.
        ///   - buttonType: The type of Apple Pay button to display. Defaults to `.plain` when `nil`.
        ///   - display: Whether Apple Pay is displayed. Defaults to `.automatic`.
        public init(
            merchantId: String,
            buttonType: PKPaymentButtonType? = nil,
            display: Display = .automatic
        ) {
                self.merchantId = merchantId
            self.buttonType = buttonType
            self.display = display
        }
    }

    public struct Appearance {
        /// Controls the theme of express payment buttons.
        public enum ButtonTheme {
            /// Light theme which contrasts with a dark background.
            case light
            /// Dark theme which contrasts with a light background.
            case dark
            /// Automatic theme which contrasts with background depending on system theme.
            case automatic
        }

        /// Controls the layout of express payment buttons.
        public struct ButtonLayout {
            /// Maximum number of columns. nil uses the default.
            public var maxColumns: Int?
            /// Maximum number of rows. nil uses the default.
            public var maxRows: Int?
            public init() {}
        }

        /// Theme of the express payment buttons.
        public var buttonTheme: ButtonTheme = .automatic

        /// Layout of the express payment buttons.
        public var buttonLayout: ButtonLayout = .init()

        public init() {}
    }

    public typealias ConfirmHandler = (_ result: Checkout.ConfirmResult) -> Void

}

extension ExpressCheckoutElement.BillingDetailsCollectionConfiguration {
    /// Converts to the equivalent `PaymentSheet.BillingDetailsCollectionConfiguration`, used to
    /// apply these requirements to the Link confirmation flow.
    var asPaymentSheetConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        func collectionMode(_ mode: CollectionMode) -> PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode {
            switch mode {
            case .automatic: return .automatic
            case .never: return .never
            case .always: return .always
            }
        }
        return PaymentSheet.BillingDetailsCollectionConfiguration(
            name: collectionMode(name),
            phone: collectionMode(phone),
            email: collectionMode(email),
            address: address == .full ? .full : .automatic
        )
    }
}
