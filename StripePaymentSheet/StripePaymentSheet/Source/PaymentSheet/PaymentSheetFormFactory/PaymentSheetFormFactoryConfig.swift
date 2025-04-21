//
//  PaymentSheetFormFactoryConfig.swift
//  StripePaymentSheet
//

import Foundation
import UIKit

@_spi(STP) import StripePayments

enum PaymentSheetFormFactoryConfig {
    case paymentElement(PaymentElementConfiguration)
    case customerSheet(CustomerSheet.Configuration)

    var hasCustomer: Bool {
        switch self {
        case .paymentElement(let config):
            return config.customer != nil
        case .customerSheet:
            return true
        }
    }
    var merchantDisplayName: String {
        switch self {
        case .paymentElement(let config):
            return config.merchantDisplayName
        case .customerSheet(let config):
            return config.merchantDisplayName
        }
    }
    var overrideCountry: String? {
        switch self {
        case .paymentElement(let config):
            return config.userOverrideCountry
        case .customerSheet:
            return nil
        }
    }
    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        switch self {
        case .paymentElement(let config):
            return config.billingDetailsCollectionConfiguration
        case .customerSheet(let config):
            return config.billingDetailsCollectionConfiguration
        }
    }
    var appearance: PaymentSheet.Appearance {
        switch self {
        case .paymentElement(let config):
            return config.appearance
        case .customerSheet(let config):
            return config.appearance
        }
    }
    var defaultBillingDetails: PaymentSheet.BillingDetails {
        switch self {
        case .paymentElement(let config):
            return config.defaultBillingDetails
        case .customerSheet(let config):
            return config.defaultBillingDetails
        }
    }
    var shippingDetails: () -> AddressViewController.AddressDetails? {
        switch self {
        case .paymentElement(let config):
            return config.shippingDetails
        case .customerSheet:
            return { return nil }
        }
    }
    var savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior {
        switch self {
        case .paymentElement(let config):
            return config.savePaymentMethodOptInBehavior
        case .customerSheet:
            return .automatic
        }
    }

    var preferredNetworks: [STPCardBrand]? {
        switch self {
        case .paymentElement(let config):
            return config.preferredNetworks
        case .customerSheet(let config):
            return config.preferredNetworks
        }
    }

    var isUsingBillingAddressCollection: Bool {
        switch self {
        case .paymentElement(let config):
            return config.requiresBillingDetailCollection()
        case .customerSheet(let config):
            return config.isUsingBillingAddressCollection()
        }
    }

    var cardBrandFilter: CardBrandFilter {
        switch self {
        case .paymentElement(let config):
            return config.cardBrandFilter
        case .customerSheet(let config):
            return config.cardBrandFilter
        }
    }

    var linkPaymentMethodsOnly: Bool {
        switch self {
        case .paymentElement(let config):
            return config.linkPaymentMethodsOnly
        case .customerSheet:
            return false
        }
    }

    var isHorizontalMode: Bool {
        switch self {
        case .paymentElement(let paymentElementConfiguration):
            switch paymentElementConfiguration.paymentMethodLayout {
            case .horizontal:
                return true
            case .vertical, .automatic:
                return false
            }
        case .customerSheet:
            return true
        }
    }

}
