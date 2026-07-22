//
//  ShippingAddress.swift
//  StripePaymentSheet
//
import Foundation

@_spi(STP)
@_spi(ReactNativeSDK)
extension Checkout.Session {
    /// Shipping address of the customer.
    public struct ShippingAddress: Equatable {
        /// The customer's full name.
        public let name: String?

        /// The customer's shipping address.
        public let address: Address

        /// Creates a shipping address.
        /// - Parameters:
        ///   - name: The customer's full name.
        ///   - address: The customer's shipping address.
        public init(name: String? = nil, address: Address) {
            self.name = name
            self.address = address
        }
    }

    /// A postal address used by Checkout's billing and shipping address APIs.
    public struct Address: Equatable {
        /// Two-letter country code (ISO 3166-1 alpha-2). Always required.
        public let country: String

        /// Address line 1 (e.g., street, PO Box, or company name).
        public let line1: String?

        /// Address line 2 (e.g., apartment, suite, unit, or building).
        public let line2: String?

        /// City, district, suburb, town, or village.
        public let city: String?

        /// ZIP or postal code.
        public let postalCode: String?

        /// State, county, province, or region.
        public let state: String?

        /// Creates an address.
        /// - Parameters:
        ///   - country: Two-letter country code (ISO 3166-1 alpha-2).
        ///   - line1: Address line 1.
        ///   - line2: Address line 2.
        ///   - city: City, district, suburb, town, or village.
        ///   - postalCode: ZIP or postal code.
        ///   - state: State, county, province, or region.
        public init(
            country: String,
            line1: String? = nil,
            line2: String? = nil,
            city: String? = nil,
            postalCode: String? = nil,
            state: String? = nil
        ) {
            self.country = country
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.postalCode = postalCode
            self.state = state
        }

        init(_ address: Checkout.Address) {
            self.init(
                country: address.country,
                line1: address.line1,
                line2: address.line2,
                city: address.city,
                postalCode: address.postalCode,
                state: address.state
            )
        }
    }
}
