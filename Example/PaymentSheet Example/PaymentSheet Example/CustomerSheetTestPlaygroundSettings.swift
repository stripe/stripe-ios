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
        case id
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

    var customerMode: CustomerMode
    var customerId: String?
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

    static func defaultValues() -> CustomerSheetTestPlaygroundSettings {
        return CustomerSheetTestPlaygroundSettings(customerMode: .new,
                                                   customerId: nil,
                                                   paymentMethodMode: .setupIntent,
                                                   applePay: .on,
                                                   headerTextForSelectionScreen: nil,
                                                   defaultBillingAddress: .off,
                                                   autoreload: .on,
                                                   attachDefaults: .off,
                                                   collectName: .automatic,
                                                   collectEmail: .automatic,
                                                   collectPhone: .automatic,
                                                   collectAddress: .automatic)
    }

    var base64Data: String {
        let jsonData = try! JSONEncoder().encode(self)
        return jsonData.base64EncodedString()
    }

    static let nsUserDefaultsKey = "CustomerSheetPlaygroundSettings"
}
