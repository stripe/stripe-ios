//
//  AddressSpec.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/**
 This represents the format of each country's dictionary in `localized_address_data.json`
 */
struct AddressSpec: Decodable {
    enum StateNameType: String, Codable {
        case area, county, department, do_si, emirate, island, oblast, parish, prefecture, state, province
        var localizedLabel: String {
            switch self {
            case .area: return String.Localized.area
            case .county: return String.Localized.county
            case .department: return String.Localized.department
            case .do_si: return String.Localized.do_si
            case .emirate: return String.Localized.emirate
            case .island: return String.Localized.island
            case .oblast: return String.Localized.oblast
            case .parish: return String.Localized.parish
            case .prefecture: return String.Localized.prefecture
            case .state: return String.Localized.state
            case .province: return String.Localized.province
            }
        }

        init(from decoder: Decoder) throws {
            let state_name_type = try decoder.singleValueContainer().decode(String.self)
            self = StateNameType(rawValue: state_name_type) ?? .prefecture
        }
    }
    enum ZipNameType: String, Codable {
        case eircode, pin, zip, postal_code
        var localizedLabel: String {
            switch self {
            case .eircode: return String.Localized.eircode
            case .pin: return String.Localized.postal_pin
            case .zip: return String.Localized.zip
            case .postal_code: return String.Localized.postal_code
            }
        }

        init(from decoder: Decoder) throws {
            let zip_name_type = try decoder.singleValueContainer().decode(String.self)
            self = ZipNameType(rawValue: zip_name_type) ?? .postal_code
        }
    }
    enum LocalityNameType: String, Codable {
        case district, suburb, post_town, suburb_or_city, city
        var localizedLabel: String {
            switch self {
            case .district: return String.Localized.district
            case .suburb: return String.Localized.suburb
            case .post_town: return String.Localized.post_town
            case .suburb_or_city: return String.Localized.suburb_or_city
            case .city: return String.Localized.city
            }
        }
        init(from decoder: Decoder) throws {
            let locality_name_type = try decoder.singleValueContainer().decode(String.self)
            self = LocalityNameType(rawValue: locality_name_type) ?? .suburb_or_city
        }
    }
    /// An enum of the fields that `AddressSpec` describes.
    enum FieldType: String {
        /// Address lines 1 and 2
        case line = "A"
        case city = "C"
        case state = "S"
        case postal = "Z"
    }

    /// The order to display the fields.
    let fieldOrdering: [FieldType]
    let requiredFields: [FieldType]
    let cityNameType: LocalityNameType
    let stateNameType: StateNameType
    let zip: String?
    let zipNameType: ZipNameType
    let subKeys: [String]? // e.g. state abbreviations - "CA"
    let subLabels: [String]? // e.g. state display names - "California"

    enum CodingKeys: String, CodingKey {
        case format = "fmt"
        case require = "require"
        case localityNameType = "locality_name_type" // e.g. City
        case stateNameType = "state_name_type"
        case zip = "zip"
        case zipNameType = "zip_name_type"
        case subKeys = "sub_keys"
        case subLabels = "sub_labels"
    }

    static var `default`: AddressSpec {
        return AddressSpec()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            format: try? container.decode(String.self, forKey: .format),
            require: try? container.decode(String.self, forKey: .require),
            cityNameType: try? container.decode(LocalityNameType.self, forKey: .localityNameType),
            stateNameType: try? container.decode(StateNameType.self, forKey: .stateNameType),
            zip: try? container.decode(String.self, forKey: .zip),
            zipNameType: try? container.decode(ZipNameType.self, forKey: .zipNameType),
            subKeys: try? container.decode([String].self, forKey: .subKeys),
            subLabels: try? container.decode([String].self, forKey: .subLabels)
        )
    }

    init(
        format: String? = nil,
        require: String? = nil,
        cityNameType: LocalityNameType? = nil,
        stateNameType: StateNameType? = nil,
        zip: String? = nil,
        zipNameType: ZipNameType? = nil,
        subKeys: [String]? = nil,
        subLabels: [String]? = nil
    ) {
        var fieldOrdering: [FieldType] = (format ?? "NACSZ").compactMap {
           FieldType(rawValue: String($0))
        }
        // We always collect line1 and line2 ("A"), so prepend if it's missing
        if !fieldOrdering.contains(FieldType.line) {
            fieldOrdering = [.line] + fieldOrdering
        }
        self.fieldOrdering = fieldOrdering
        self.requiredFields = (require ?? "ACSZ").compactMap {
            FieldType(rawValue: String($0))
        }
        self.cityNameType = cityNameType ?? .city
        self.stateNameType = stateNameType ?? .province
        self.zip = zip
        self.zipNameType = zipNameType ?? .postal_code
        self.subKeys = subKeys
        self.subLabels = subLabels
    }
}
