//
//  AddressSpec.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/**
 This represents the format of each country's dictionary in `localized_address_data.json`
 */
struct AddressSpec: Codable {
    enum StateNameType: String, Codable {
        case area, county, department, do_si, emirate, island, oblast, parish, prefecture, state, province
        var localizedLabel: String {
            switch self {
            case .area: return String.Localized.area
            case .county: return .Localized.county
            case .department: return .Localized.department
            case .do_si: return .Localized.do_si
            case .emirate: return .Localized.emirate
            case .island: return .Localized.island
            case .oblast: return .Localized.oblast
            case .parish: return .Localized.parish
            case .prefecture: return .Localized.prefecture
            case .state: return .Localized.state
            case .province: return .Localized.province
            }
        }
        
        init(from decoder: Decoder) throws {
            let state_name_type = try decoder.singleValueContainer().decode(String.self)
            self = .init(rawValue: state_name_type) ?? .prefecture
        }
    }
    enum ZipNameType: String, Codable {
        case eircode, pin, zip, postal_code
        var localizedLabel: String {
            switch self {
            case .eircode: return .Localized.eircode
            case .pin: return .Localized.postal_pin
            case .zip: return .Localized.zip
            case .postal_code: return .Localized.postal_code
            }
        }
        
        init(from decoder: Decoder) throws {
            let zip_name_type = try decoder.singleValueContainer().decode(String.self)
            self = .init(rawValue: zip_name_type) ?? .postal_code
        }
    }
    enum CityNameType: String, Codable {
        case district, suburb, post_town, suburb_or_city, city
        var localizedLabel: String {
            switch self {
            case .district: return .Localized.district
            case .suburb: return .Localized.suburb
            case .post_town: return .Localized.post_town
            case .suburb_or_city: return .Localized.suburb_or_city
            case .city: return .Localized.city
            }
        }
        init(from decoder: Decoder) throws {
            let city_name_type = try decoder.singleValueContainer().decode(String.self)
            self = .init(rawValue: city_name_type) ?? .suburb_or_city
        }
    }
    
    let format: String
    let require: String
    let cityNameType: CityNameType
    let stateNameType: StateNameType
    let zip: String?
    let zipNameType: ZipNameType
    
    enum CodingKeys: String, CodingKey {
        case format = "fmt"
        case require = "require"
        case cityNameType = "city_name_type"
        case stateNameType = "state_name_type"
        case zip = "zip"
        case zipNameType = "zip_name_type"
    }
    
    static var `default`: AddressSpec {
        return AddressSpec()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            format: try? container.decode(String.self, forKey: .format),
            require: try? container.decode(String.self, forKey: .require),
            cityNameType: try? container.decode(CityNameType.self, forKey: .cityNameType),
            stateNameType: try? container.decode(StateNameType.self, forKey: .stateNameType),
            zip: try? container.decode(String.self, forKey: .zip),
            zipNameType: try? container.decode(ZipNameType.self, forKey: .zipNameType)
        )
    }
    
    init(
        format: String? = nil,
        require: String? = nil,
        cityNameType: CityNameType? = nil,
        stateNameType: StateNameType? = nil,
        zip: String? = nil,
        zipNameType: ZipNameType? = nil
    ) {
        self.format = format ?? "NACSZ"
        self.require = require ?? "ACSZ"
        self.cityNameType = cityNameType ?? .city
        self.stateNameType = stateNameType ?? .province
        self.zip = zip
        self.zipNameType = zipNameType ?? .postal_code
    }
}
