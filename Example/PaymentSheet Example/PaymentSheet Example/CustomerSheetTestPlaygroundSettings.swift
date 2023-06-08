//
//  CustomerSheetTestPlaygroundSettings.swift
//  PaymentSheet Example
//

import Foundation

struct CustomerSheetTestPlaygroundSettings: Codable, Equatable {
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
    enum Autoreload: String, PickerEnum {
        static var enumName: String { "Autoreload" }

        case on
        case off
    }
    var customerMode: CustomerMode
    var customerId: String?
    var paymentMethodMode: PaymentMethodMode
    var applePay: ApplePay
    var headerTextForSelectionScreen: String?
    var autoreload: Autoreload

    static func defaultValues() -> CustomerSheetTestPlaygroundSettings {
        return CustomerSheetTestPlaygroundSettings(customerMode: .new,
                                                   customerId: nil,
                                                   paymentMethodMode: .setupIntent,
                                                   applePay: .on,
                                                   headerTextForSelectionScreen: nil,
                                                   autoreload: .on)
    }

    static let nsUserDefaultsKey = "CustomerSheetPlaygroundSettings"
}
