//
//  STPAnalyticsClient+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

@objc(STPBasicUIAnalyticsSerializer)
class STPBasicUIAnalyticsSerializer: NSObject, STPAnalyticsSerializer {
    static func serializeConfiguration(
        _ configuration: NSObject
    ) -> [String:
        String]
    {
        var dictionary: [String: String] = [:]
        dictionary["publishable_key"] = STPAPIClient.shared.publishableKey ?? "unknown"

        guard let configuration = configuration as? STPPaymentConfiguration else {
            return dictionary
        }

        if configuration.applePayEnabled && !configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "default"
        } else if !configuration.applePayEnabled && !configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "none"
        } else if !configuration.applePayEnabled && configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "fpx"
        } else if configuration.applePayEnabled && configuration.fpxEnabled {
            dictionary["additional_payment_methods"] = "applepay,fpx"
        }

        switch configuration.requiredBillingAddressFields {
        case .none:
            dictionary["required_billing_address_fields"] = "none"
        case .postalCode:
            dictionary["required_billing_address_fields"] = "zip"
        case .full:
            dictionary["required_billing_address_fields"] = "full"
        case .name:
            dictionary["required_billing_address_fields"] = "name"
        default:
            fatalError()
        }

        var shippingFields: [String] = []
        if let shippingAddressFields = configuration.requiredShippingAddressFields {
            if shippingAddressFields.contains(.name) {
                shippingFields.append("name")
            }
            if shippingAddressFields.contains(.emailAddress) {
                shippingFields.append("email")
            }
            if shippingAddressFields.contains(.postalAddress) {
                shippingFields.append("address")
            }
            if shippingAddressFields.contains(.phoneNumber) {
                shippingFields.append("phone")
            }
        }

        if shippingFields.isEmpty {
            shippingFields.append("none")
        }
        dictionary["required_shipping_address_fields"] = shippingFields.joined(separator: "_")

        switch configuration.shippingType {
        case .shipping:
            dictionary["shipping_type"] = "shipping"
        case .delivery:
            dictionary["shipping_type"] = "delivery"
        @unknown default:
            break
        }

        dictionary["company_name"] = configuration.companyName
        dictionary["apple_merchant_identifier"] = configuration.appleMerchantIdentifier ?? "unknown"
        return dictionary
    }
}
