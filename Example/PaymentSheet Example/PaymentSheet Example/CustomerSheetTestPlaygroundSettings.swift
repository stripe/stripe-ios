//
//  CustomerSheetTestPlaygroundSettings.swift
//  PaymentSheet Example
//

import Foundation

public struct CustomerSheetTestPlaygroundSettings: Codable, Equatable {
    enum CustomerMode: String, PickerEnum {
        static var enumName: String { "CustomerMode" }

        case new
        case returning
        case customID
    }
    enum CustomerKeyType: String, PickerEnum {
        static var enumName: String { "CustomerKeyType" }

        case legacy
        case customerSession = "customer_session"
    }
    enum PaymentMethodMode: String, PickerEnum {
        static var enumName: String { "PaymentMethodMode" }

        case setupIntent
        case createAndAttach
    }
    enum ApplePay: String, PickerEnum {
        static var enumName: String { "ApplePay" }

        case on
        case off
    }
    enum DefaultBillingAddress: String, PickerEnum {
        static var enumName: String { "Default billing address" }

        case on
        case off
    }
    enum Autoreload: String, PickerEnum {
        static var enumName: String { "Autoreload" }

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
    enum MerchantCountry: String, PickerEnum {
        static var enumName: String { "MerchantCountry" }

        case US
        case FR
    }
    enum PreferredNetworksEnabled: String, PickerEnum {
        static let enumName: String = "Preferred Networks (CBC)"

        case on
        case off

        var displayName: String {
            switch self {
            case .on:
                return "[visa, cartesBancaires]"
            case .off:
                return "off"
            }
        }
    }
    enum AllowsRemovalOfLastSavedPaymentMethod: String, PickerEnum {
        static let enumName: String = "AllowsRemovalOfLastSavedPaymentMethod"

        case on
        case off
    }
    enum PaymentMethodRemove: String, PickerEnum {
        static let enumName: String = "PaymentMethodRemove"

        case enabled
        case disabled
    }
    enum PaymentMethodRemoveLast: String, PickerEnum {
        static let enumName: String = "PaymentMethodRemoveLast"

        case enabled
        case disabled
    }
    enum PaymentMethodAllowRedisplayFilters: String, PickerEnum {
        static var enumName: String { "PaymentMethodRedisplayFilters" }

        case always
        case limited
        case unspecified
        case unspecified_limited_always
        case notSet

        func arrayValue() -> [String]? {
            switch self {
            case .always:
                return ["always"]
            case .limited:
                return ["limited"]
            case .unspecified:
                return ["unspecified"]
            case .unspecified_limited_always:
                return ["unspecified", "limited", "always"]
            case .notSet:
                return nil
            }
        }
    }

    enum CardBrandAcceptance: String, PickerEnum {
        static let enumName: String = "cardBrandAcceptance"
        case all
        case blockAmEx
        case allowVisa
    }

    enum AllowsSetAsDefaultPM: String, PickerEnum {
        static let enumName: String = "allowsSetAsDefaultPM"
        case on
        case off
    }

    var customerMode: CustomerMode
    var customerId: String?
    var customerKeyType: CustomerKeyType
    var paymentMethodMode: PaymentMethodMode
    var applePay: ApplePay
    var headerTextForSelectionScreen: String?
    var defaultBillingAddress: DefaultBillingAddress
    var autoreload: Autoreload

    var attachDefaults: BillingDetailsAttachDefaults
    var collectName: BillingDetailsName
    var collectEmail: BillingDetailsEmail
    var collectPhone: BillingDetailsPhone
    var collectAddress: BillingDetailsAddress
    var merchantCountryCode: MerchantCountry
    var preferredNetworksEnabled: PreferredNetworksEnabled
    var allowsRemovalOfLastSavedPaymentMethod: AllowsRemovalOfLastSavedPaymentMethod
    var paymentMethodRemove: PaymentMethodRemove
    var paymentMethodRemoveLast: PaymentMethodRemoveLast
    var paymentMethodAllowRedisplayFilters: PaymentMethodAllowRedisplayFilters
    var cardBrandAcceptance: CardBrandAcceptance
    var allowsSetAsDefaultPM: AllowsSetAsDefaultPM

    static func defaultValues() -> CustomerSheetTestPlaygroundSettings {
        return CustomerSheetTestPlaygroundSettings(customerMode: .new,
                                                   customerId: nil,
                                                   customerKeyType: .legacy,
                                                   paymentMethodMode: .setupIntent,
                                                   applePay: .on,
                                                   headerTextForSelectionScreen: nil,
                                                   defaultBillingAddress: .off,
                                                   autoreload: .on,
                                                   attachDefaults: .off,
                                                   collectName: .automatic,
                                                   collectEmail: .automatic,
                                                   collectPhone: .automatic,
                                                   collectAddress: .automatic,
                                                   merchantCountryCode: .US,
                                                   preferredNetworksEnabled: .off,
                                                   allowsRemovalOfLastSavedPaymentMethod: .on,
                                                   paymentMethodRemove: .enabled,
                                                   paymentMethodRemoveLast: .enabled,
                                                   paymentMethodAllowRedisplayFilters: .always,
                                                   cardBrandAcceptance: .all,
                                                   allowsSetAsDefaultPM: .off)
    }

    var base64Data: String {
        let jsonData = try! JSONEncoder().encode(self)
        return jsonData.base64EncodedString()
    }

    static let nsUserDefaultsKey = "CustomerSheetPlaygroundSettings"
}
