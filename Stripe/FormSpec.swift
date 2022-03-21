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
    /// The types of Elements we support
    enum ElementType: String, Decodable {
        case name
        case email
        case customDropdown
    }

    enum ElementSpec: Decodable, Equatable {
        case name
        case email
        case customDropdown(DropdownElementSpec)
        
        // MARK: Decodable
        
        private enum CodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            switch try container.decode(String.self, forKey: .type) {
            case "name":
                self = .name
            case "email":
                self = .email
            case "custom_dropdown":
                self = .customDropdown(try DropdownElementSpec(from: decoder))
            default:
                fatalError("Unknown type")
            }
        }
    }
    
    let elements: [ElementSpec]
}

extension FormSpec {
    struct DropdownElementSpec: Decodable, Equatable {
        struct DropdownItemSpec: Decodable, Equatable {
            /// The localized text to display for this item in the dropdown
            let localizedDisplayText: String
            /// The value to send to the Stripe API if the customer selects this dropdown item
            let apiValue: String
        }
        /// A form URL encoded key, whose value is `DropdownItemSpec.apiValue`
        let paymentMethodDataPath: String
        /// The list of items to display in the dropdown
        let dropdownItems: [DropdownItemSpec]
        /// The dropdown's label
        let label: LocalizedString
    }
}

extension FormSpec {
    // For now, we'll deal with localized strings by hardcoding this enum.
    // In the future, the server will provide an already-localized string
    enum LocalizedString: String, Decodable {
        case ideal_bank = "iDEAL Bank"
        
        var localizedValue: String {
            switch self {
            case .ideal_bank:
                return String.Localized.ideal_bank
            }
        }
    }
}
