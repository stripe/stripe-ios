//
//  AddressViewController+Types.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

public extension AddressViewController {
    /// 🏗 Under construction
    /// Contains Customer information related to address.
    struct AddressDetails {
        public let address: PaymentSheet.Address
        public let name: String?
        public let phone: String?
        
        public init(address: PaymentSheet.Address = .init(), name: String? = nil, phone: String? = nil) {
            self.address = address
            self.name = name
            self.phone = phone
        }
    }
    
    /// 🏗 Under construction
    /// Configuration related to address collection.
    struct Configuration {
        public init(defaultValues: AddressViewController.AddressDetails = .init(), additionalFields: AddressViewController.Configuration.AdditionalFields = .init(), allowedCountries: [String] = [], appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default) {
            self.defaultValues = defaultValues
            self.additionalFields = additionalFields
            self.allowedCountries = allowedCountries
            self.appearance = appearance
        }
        
        /// 🏗 Under construction
        /// Configuration related to the collection of additional fields beyond the physical address.
        public struct AdditionalFields {
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
            
            /// Initializes an AddressFields
            public init(name: FieldConfiguration = .required, phone: FieldConfiguration = .hidden) {
                self.name = name
                self.phone = phone
            }
        }

        /// The values to pre-populate address fields with.
        public var defaultValues: AddressDetails = .init()
        
        /// Fields to collect in addition to the physical address.
        /// By default, no additional fields are collected.
        public var additionalFields: AdditionalFields = .init()
        
        /// A list of two-letter country codes representing countries the customers can select.
        /// If the list is empty (the default), we display all countries.
        public var allowedCountries: [String] = []
        
        /// Configuration for the appearance of the UI
        public var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default
    }
}
