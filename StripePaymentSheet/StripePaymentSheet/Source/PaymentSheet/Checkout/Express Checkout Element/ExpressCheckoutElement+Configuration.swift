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
        /// A closure called after a wallet payment confirmation completes.
        public typealias ConfirmHandler = (_ result: CheckoutController.ConfirmResult) -> Void

        /// Configuration for collecting billing details.
        public var billingDetailsCollectionConfiguration: BillingDetailsCollectionConfiguration = .init()

        /// Called after a wallet payment confirmation completes.
        public var confirmHandler: ConfirmHandler = { _ in }

        /// Sets the configuration for Apple Pay.
        public var applePayConfiguration: ApplePayConfiguration?
        /// Sets the configuration for Link.
        public var linkConfiguration: LinkConfiguration = .init()

        /// Creates a configuration with default values.
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

    /// Configuration for Apple Pay.
    public struct ApplePayConfiguration: CheckoutApplePayConfiguration {
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

        /// Creates a Link configuration.
        public init(display: Display = .automatic) {
            self.display = display
        }
    }
}

extension ExpressCheckoutElement.BillingDetailsCollectionConfiguration: CheckoutBillingDetailsCollectionConfiguration {
    /// Billing contact fields to require in the Apple Pay sheet.
    var requiredBillingContactFields: Set<PKContactField> {
        var requiredPKContactFields = Set<PKContactField>()
        // By default, we always want to request the billing address (as it includes the postal code).
        if address == .automatic || address == .full {
            requiredPKContactFields.insert(.postalAddress)
        }
        // Only request name field - phone and email go into shipping contact fields
        if name == .always {
            requiredPKContactFields.insert(.name)
        }
        return requiredPKContactFields
    }

    /// Shipping contact fields to require in the Apple Pay sheet, used to collect email/phone.
    var requiredShippingContactFields: Set<PKContactField> {
        var requiredPKContactFields = Set<PKContactField>()
        // Phone and email are collected through shipping contact fields
        if email == .always {
            requiredPKContactFields.insert(.emailAddress)
        }
        if phone == .always {
            requiredPKContactFields.insert(.phoneNumber)
        }
        return requiredPKContactFields
    }
}
