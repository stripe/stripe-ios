//
//  PaymentSheetTestPlaygroundSettings.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import Foundation

struct PaymentSheetTestPlaygroundSettings: Codable {
    enum Mode: String, PickerEnum {
        static var enumName: String { "Mode" }
        
        case payment
        case paymentWithSetup = "payment_with_setup"
        case setup
    }
    
    enum IntegrationType: String, PickerEnum {
        static var enumName: String { "Type" }
        
        // Normal: Normal client side confirmation non-deferred flow
        case normal
        /// Def CSC: Deferred client side confirmation
        case deferred_csc
        /// Def SSC: Deferred server side confirmation
        case deferred_ssc
        /// Def MC: Deferred server side confirmation with manual confirmation
        case deferred_mc
        /// Def MP: Deferred multiprocessor flow
        case deferred_mp
    }
    
    enum CustomerMode: String, PickerEnum {
        static var enumName: String { "Customer" }
        
        case guest
        case new
        case returning
    }
    
    enum Currency: String, PickerEnum {
        static var enumName: String { "Currency" }
        
        case usd
        case eur
        case aud
        case gbp
        case inr
    }

    enum MerchantCountry: String, PickerEnum {
        static var enumName: String { "MerchantCountry" }
        
        case US
        case GB
        case AU
        case FR
        case IN
    }
    
    enum APMSEnabled: String, PickerEnum {
        static var enumName: String { "Automatic PMs" }
        
        case on
        case off
    }
    
    enum ShippingInfo: String, PickerEnum {
        static var enumName: String { "Shipping info" }
        
        case on
        case onWithDefaults = "on w/ defaults"
        case off
    }

    enum ApplePayEnabled: String, PickerEnum {
        static var enumName: String { "Apple Pay" }
        
        case on
        case off
        case onWDetails = "on w/details"
    }
    
    enum ApplePayButtonType: String, PickerEnum {
        static var enumName: String { "Pay button" }
        
        case plain
        case buy
        case setup
        case checkout
    }
    
    enum AllowsDelayedPMs: String, PickerEnum {
        static var enumName: String { "allowsDelayedPMs" }
        
        case `true`
        case `false`
    }

    enum DefaultBillingAddress: String, PickerEnum {
        static var enumName: String { "Default billing address" }
        
        case on
        case off
    }
    
    enum LinkEnabled: String, PickerEnum {
        static var enumName: String { "Link" }
        
        case on
        case off
    }

    enum BillingDetailsAttachDefaults: String, PickerEnum {
        static var enumName: String { "Attach defaults" }
        
        case on
        case off
    }
    
    enum BillingDetailsName: String, PickerEnum {
        static var enumName: String { "Name" }
        
        case automatic
        case never
        case always
    }
    enum BillingDetailsEmail: String, PickerEnum {
        static var enumName: String { "Email" }
        
        case automatic
        case never
        case always
    }
    enum BillingDetailsPhone: String, PickerEnum {
        static var enumName: String { "Phone" }
        
        case automatic
        case never
        case always
    }
    enum BillingDetailsAddress: String, PickerEnum {
        static var enumName: String { "Address" }
        
        case automatic
        case never
        case full
    }

    var mode: Mode
    var integrationType: IntegrationType
    var customerMode: CustomerMode
    var currency: Currency
    var merchantCountryCode: MerchantCountry
    var apmsEnabled: APMSEnabled

    var shippingInfo: ShippingInfo
    var applePayEnabled: ApplePayEnabled
    var applePayButtonType: ApplePayButtonType
    var allowsDelayedPMs: AllowsDelayedPMs
    var defaultBillingAddress: DefaultBillingAddress
    var linkEnabled: LinkEnabled
    var customCtaLabel: String?
    var checkoutEndpoint: String?
    
    var attachDefaults: BillingDetailsAttachDefaults
    var collectName: BillingDetailsName
    var collectEmail: BillingDetailsEmail
    var collectPhone: BillingDetailsPhone
    var collectAddress: BillingDetailsAddress

    static func defaultValues() -> PaymentSheetTestPlaygroundSettings {
        return PaymentSheetTestPlaygroundSettings(
            mode: .payment,
            integrationType: .normal,
            customerMode: .guest,
            currency: .usd,
            merchantCountryCode: .US,
            apmsEnabled: .on,
            shippingInfo: .off,
            applePayEnabled: .on,
            applePayButtonType: .buy,
            allowsDelayedPMs: .false,
            defaultBillingAddress: .off,
            linkEnabled: .off,
            customCtaLabel: nil,
            checkoutEndpoint: PlaygroundController.defaultCheckoutEndpoint,
            attachDefaults: .off,
            collectName: .automatic,
            collectEmail: .automatic,
            collectPhone: .automatic,
            collectAddress: .automatic)
    }
    
    static let nsUserDefaultsKey = "PaymentSheetTestPlaygroundSettings"
}
