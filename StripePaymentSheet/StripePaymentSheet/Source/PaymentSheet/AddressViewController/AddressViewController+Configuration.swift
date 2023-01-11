//
//  AddressViewController+Configuration.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

public extension AddressViewController {
    /// The customer data collected by `AddressViewController`
    struct AddressDetails {
        /// The customer's address
        public let address: Address

        /// The customer's full name
        public let name: String?

        /// The customer's phone number, in E.164 format (e.g. "+15551234567")
        public let phone: String?

        /// Whether or not the checkbox is enabled.
        /// Seealso: `AdditionalFieldsConfiguration.checkboxLabel`
        public let isCheckboxSelected: Bool?

        /// Initializes an AddressDetails
        public init(address: Address, name: String? = nil, phone: String? = nil, isCheckboxSelected: Bool? = nil) {
            self.address = address
            self.name = name
            self.phone = phone
            self.isCheckboxSelected = isCheckboxSelected
        }

        /// An address collected by `AddressViewController`
        public struct Address {
            /// City, district, suburb, town, or village.
            public let city: String?

            /// Two-letter country code (ISO 3166-1 alpha-2).
            public let country: String

            /// Address line 1 (e.g., street, PO Box, or company name).
            public let line1: String

            /// Address line 2 (e.g., apartment, suite, unit, or building).
            public let line2: String?

            /// ZIP or postal code.
            public let postalCode: String?

            /// State, county, province, or region.
            public let state: String?

            /// Initializes an Address
            public init(city: String? = nil, country: String, line1: String, line2: String? = nil, postalCode: String? = nil, state: String? = nil) {
                self.city = city
                self.country = country
                self.line1 = line1
                self.line2 = line2
                self.postalCode = postalCode
                self.state = state
            }
        }
    }

    /// Configuration for an `AddressViewController` instance.
    struct Configuration {
        /// Initializes a Configuration
        public init(
            defaultValues: DefaultAddressDetails = .init(),
            additionalFields: AddressViewController.Configuration.AdditionalFields = .init(),
            allowedCountries: [String] = [],
            appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default,
            buttonTitle: String? = nil,
            title: String? = nil
        ) {
            self.defaultValues = defaultValues
            self.additionalFields = additionalFields
            self.allowedCountries = allowedCountries
            self.appearance = appearance
            self.buttonTitle = buttonTitle ?? .Localized.save_address
            self.title = title ?? .Localized.shipping_address
        }

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

            /// Configuration for the field that collects a phone number.
            public var phone: FieldConfiguration

            /// The label of a checkbox displayed below other fields. If nil, the checkbox is not displayed.
            /// Defaults to nil
            public var checkboxLabel: String?

            /// Initializes an AdditionalFields
            public init(phone: FieldConfiguration = .hidden, checkboxLabel: String? = nil) {
                self.phone = phone
                self.checkboxLabel = checkboxLabel
            }
        }

        /// Default values for the fields collected by `AddressViewController`
        public struct DefaultAddressDetails {
            /// The customer's address
            public var address: PaymentSheet.Address

            /// The customer's full name
            public var name: String?

            /// The customer's phone number, without formatting (e.g. "5551234567") or in E.164 format (e.g. "+15551234567")
            public var phone: String?

            /// Whether or not your custom checkbox is initially selected.
            /// - Note: The checkbox is displayed below the other fields when `AdditionalFieldsConfiguration.checkboxLabel` is set.
            public var isCheckboxSelected: Bool?

            /// Initializes an AddressDetails
            public init(address: PaymentSheet.Address = .init(), name: String? = nil, phone: String? = nil, isCheckboxSelected: Bool? = nil) {
                self.address = address
                self.name = name
                self.phone = phone
                self.isCheckboxSelected = isCheckboxSelected
            }
        }

        /// The values to pre-populate address fields with.
        public var defaultValues: DefaultAddressDetails = .init()

        /// Fields to collect in addition to the physical address.
        /// By default, no additional fields are collected.
        public var additionalFields: AdditionalFields = .init()

        /// A list of two-letter country codes representing countries the customers can select.
        /// If the list is empty (the default), we display all countries.
        public var allowedCountries: [String] = []

        /// Configuration for the look and feel of the UI
        public var appearance: PaymentSheet.Appearance = PaymentSheet.Appearance.default

        /// The title of the primary button displayed at the bottom of the screen. Defaults to "Save address".
        public var buttonTitle: String = .Localized.save_address

        /// The title of the view controller. Defaults to "Shipping address".
        public var title: String = .Localized.shipping_address

        /// The APIClient instance used to make requests to Stripe
        public var apiClient: STPAPIClient = .shared

        /// A list of two-letter country codes that support autocomplete
        /// Defaults to a list of countries that Stripe has audited to ensure a good autocomplete experience.
        public var autocompleteCountries: [String] = ["AU", "BE", "BR", "CA", "CH", "DE", "ES", "FR", "GB", "IE", "IT", "MX", "NO", "NL", "PL", "RU", "SE", "TR", "US", "ZA"]
    }
}
