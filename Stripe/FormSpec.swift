//
//  FormSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/// A decodable representation that can used to construct a `FormElement`
struct FormSpec: Decodable {
    let code: String
    let async: Bool?
    let fields: [FieldSpec]

    enum FieldSpec: Decodable, Equatable {
        case name
        case email
        case selector(SelectorSpec)

        private enum CodingKeys: String, CodingKey {
            case fieldType
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let field_type = try container.decode(String.self, forKey: .fieldType)

            switch(field_type) {
            case "name":
                self = .name
            case "email":
                self = .email
            case "selector":
                self = .selector(try SelectorSpec(from: decoder))
            default:
                fatalError("Unknown fieldType")
            }
        }
    }
}

extension FormSpec {
    struct SelectorSpec: Decodable, Equatable {
        struct SelectorPropertySpec: Decodable, Equatable {
            struct PropertyItemSpec: Decodable, Equatable {
                /// The localized text to display for this item in the dropdown
                let displayText: String
                /// The value to send to the Stripe API if the customer selects this dropdown item
                let apiValue: String?
            }
            /// This value will be set to "selector"
            let type: String
            /// The dropdown's label
            let label: LocalizedString
            /// The list of items to display in the dropdown
            let items: [PropertyItemSpec]
            /// A form URL encoded key, whose value is `DropdownItemSpec.apiValue`
            let apiKey: String
        }
        let property: SelectorPropertySpec
    }
}

extension FormSpec {
    // For now, we'll deal with localized strings by hardcoding this enum.
    // In the future, the server will provide an already-localized string
    enum LocalizedString: String, Decodable {
        case ideal_bank = "Ideal Bank"
        
        var localizedValue: String {
            switch self {
            case .ideal_bank:
                return String.Localized.ideal_bank
            }
        }
    }
}
