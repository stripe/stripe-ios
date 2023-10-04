//
//  PaymentSheetFormFactoryConfig.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP) import StripePayments

enum PaymentSheetFormFactoryConfig {
    case paymentSheet(PaymentSheet.Configuration)
    case customerSheet(CustomerSheet.Configuration)

    var hasCustomer: Bool {
        switch self {
        case .paymentSheet(let config):
            return config.customer != nil
        case .customerSheet:
            return true
        }
    }
    var merchantDisplayName: String {
        switch self {
        case .paymentSheet(let config):
            return config.merchantDisplayName
        case .customerSheet(let config):
            return config.merchantDisplayName
        }
    }
    var linkPaymentMethodsOnly: Bool {
        switch self {
        case .paymentSheet(let config):
            return config.linkPaymentMethodsOnly
        case .customerSheet:
            return false
        }
    }
    var billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration {
        switch self {
        case .paymentSheet(let config):
            return config.billingDetailsCollectionConfiguration
        case .customerSheet(let config):
            return config.billingDetailsCollectionConfiguration
        }
    }
    var appearance: PaymentSheet.Appearance {
        switch self {
        case .paymentSheet(let config):
            return config.appearance
        case .customerSheet(let config):
            return config.appearance
        }
    }
    var defaultBillingDetails: PaymentSheet.BillingDetails {
        switch self {
        case .paymentSheet(let config):
            return config.defaultBillingDetails
        case .customerSheet(let config):
            return config.defaultBillingDetails
        }
    }
    var shippingDetails: () -> AddressViewController.AddressDetails? {
        switch self {
        case .paymentSheet(let config):
            return config.shippingDetails
        case .customerSheet:
            return { return nil }
        }
    }
    var savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior {
        switch self {
        case .paymentSheet(let config):
            return config.savePaymentMethodOptInBehavior
        case .customerSheet:
            return .automatic
        }
    }

    var preferredNetworks: [STPCardBrand]? {
        switch self {
        case .paymentSheet(let config):
            return config.preferredNetworks
        case .customerSheet:
            // TODO(porter) Support CBC in CustomerSheet
            return nil
        }
    }
}
