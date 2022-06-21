//
//  PaymentSheet+Shipping.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) public extension PaymentSheet {
    /// 🏗 Under construction
    /// Contains Customer information related to shipping address.
    struct ShippingAddressDetails {
        public let address: Address
        public let name: String?
        public let phone: String?
        public let company: String?
        
        public init(address: Address = .init(), name: String? = nil, phone: String? = nil, company: String? = nil) {
            self.address = address
            self.name = name
            self.phone = name
            self.company = company
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
            
            /// Configuration for the field that collects a full name.
            public var name: FieldConfiguration
            
            /// Configuration for the field that collects a phone number.
            public var phone: FieldConfiguration
            
            /// Configuration for the field that collects the name of a company.
            public var company: FieldConfiguration
            
            /// Initializes a ShippingAddressFields
            public init(name: FieldConfiguration = .hidden, phone: FieldConfiguration = .hidden, company: FieldConfiguration = .hidden) {
                self.name = name
                self.phone = phone
                self.company = company
            }
        }

        /// The values to pre-populate shipping address fields with.
        public var defaultValues: ShippingAddressDetails = .init()
        
        /// Fields to collect in addition to the physical shipping address.
        /// By default, no additional fields are collected.
        public var additionalFields: AdditionalFields = .init()
        
        /// A list of two-letter country codes representing countries the customers can select.
        /// If the list is empty (the default), we display all countries.
        public var allowedCountries: [String] = []
    }
}
