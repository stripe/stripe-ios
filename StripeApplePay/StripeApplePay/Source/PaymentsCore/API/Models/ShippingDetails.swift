//
//  ShippingDetails.swift
//  StripeApplePay
//
//  Created by Yuki Tokuhiro on 8/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    @_spi(STP) public struct ShippingDetails: UnknownFieldsCodable, Equatable {
        @_spi(STP) public init(
            address: StripeAPI.ShippingDetails.Address,
            name: String,
            carrier: String? = nil,
            phone: String? = nil,
            trackingNumber: String? = nil,
            _allResponseFieldsStorage: NonEncodableParameters? = nil,
            _additionalParametersStorage: NonEncodableParameters? = nil
        ) {
            self.address = address
            self.name = name
            self.carrier = carrier
            self.phone = phone
            self.trackingNumber = trackingNumber
            self._allResponseFieldsStorage = _allResponseFieldsStorage
            self._additionalParametersStorage = _additionalParametersStorage
        }

        /// Shipping address.
        @_spi(STP) public var address: Address

        /// Recipient name.
        @_spi(STP) public var name: String

        /// The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
        @_spi(STP) public var carrier: String?

        /// Recipient phone (including extension).
        @_spi(STP) public var phone: String?

        /// The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
        @_spi(STP) public var trackingNumber: String?

        @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?
        @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?

        @_spi(STP) public struct Address: UnknownFieldsCodable, Equatable {
            @_spi(STP) public init(
                city: String? = nil,
                country: String? = nil,
                line1: String,
                line2: String? = nil,
                postalCode: String? = nil,
                state: String? = nil,
                _allResponseFieldsStorage: NonEncodableParameters? = nil,
                _additionalParametersStorage: NonEncodableParameters? = nil
            ) {
                self.city = city
                self.country = country
                self.line1 = line1
                self.line2 = line2
                self.postalCode = postalCode
                self.state = state
                self._allResponseFieldsStorage = _allResponseFieldsStorage
                self._additionalParametersStorage = _additionalParametersStorage
            }

            /// City/District/Suburb/Town/Village.
            @_spi(STP) public var city: String?

            /// Two-letter country code (ISO 3166-1 alpha-2).
            @_spi(STP) public var country: String?

            /// Address line 1 (Street address/PO Box/Company name).
            @_spi(STP) public var line1: String

            /// Address line 2 (Apartment/Suite/Unit/Building).
            @_spi(STP) public var line2: String?

            /// ZIP or postal code.
            @_spi(STP) public var postalCode: String?

            /// State/County/Province/Region.
            @_spi(STP) public var state: String?

            @_spi(STP) public var _allResponseFieldsStorage: NonEncodableParameters?
            @_spi(STP) public var _additionalParametersStorage: NonEncodableParameters?
        }
    }
}
