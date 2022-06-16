//
//  PaymentSheet+Shipping.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import Contacts

@_spi(STP) public extension PaymentSheet {
    /// 🏗 Under construction
    /// Contains Customer information related to shipping address.
    struct ShippingAddressDetails {
        public let address: Address
        public let name: String?
        
        /// A user-facing description of the shipping address details.
        @_spi(STP) public var localizedDescription: String {
            let formatter = CNPostalAddressFormatter()

            let postalAddress = CNMutablePostalAddress()
            if let line1 = address.line1, !line1.isEmpty,
               let line2 = address.line2, !line2.isEmpty {
                postalAddress.street = "\(line1), \(line2)"
            } else {
                postalAddress.street = "\(address.line1 ?? "")\(address.line2 ?? "")"
            }
            postalAddress.postalCode = address.postalCode ?? ""
            postalAddress.city = address.city ?? ""
            postalAddress.state = address.state ?? ""
            postalAddress.country = address.country ?? ""

            return formatter.string(from: postalAddress)
        }
        
        public init(address: Address = .init(), name: String? = nil) {
            self.address = address
            self.name = name
        }
    }
    
    /// 🏗 Under construction
    /// Configuration related to shipping address collection.
    struct ShippingAddressConfiguration {
        /// 🏗 Under construction
        /// Configuration related to the collection of additional fields beyond the physical shipping address.
        @_spi(STP) public struct AdditionalFields {
            /// Whether a field should be hidden, optional, or required.
            public enum FieldConfiguration {
                /// The field is not displayed.
                case hidden
                /// The field is displayed, but the customer can leave it blank.
                case optional
                /// The field is displayed, but the customer is required to fill it in. If the customer doesn't, the sheet displays an error and disables the continue button.
                case required
            }
            
            /// Configuration for the name field.
            public var name: FieldConfiguration = .hidden
            
            /// Initializes a ShippingAddressFields
            public init(name: FieldConfiguration = .hidden) {
                self.name = name
            }
        }

        /// The values to pre-populate shipping address fields with.
        public var defaultValues: ShippingAddressDetails = .init(address: .init(), name: nil)
        
        /// Fields to collect in addition to the physical shipping address.
        /// By default, no additional fields are collected.
        public var additionalFields: AdditionalFields = .init()
        
        /// A list of two-letter country codes representing countries the customers can select.
        /// If the list is empty (the default), we display all countries.
        public var allowedCountries: [String] = []
    }
}
