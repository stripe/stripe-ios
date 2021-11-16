//
//  Device.swift
//  CardVerify
//
//  Created by Jaime Park on 12/30/20.
//

import Foundation

struct ClientIds: Encodable {
    var vendorId: String?

    enum CodingKeys: String, CodingKey {
        case vendorId = "vendor_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(vendorId, forKey: .vendorId)
    }
}

struct Device: Encodable {
    let ids = ClientIds(vendorId: ClientIdsUtils.vendorId)
    let name: String = DeviceUtils.name
    let bootCount: Int? = DeviceUtils.bootCount
    let locale: String? = DeviceUtils.locale
    let carrier: String? = DeviceUtils.carrier
    let networkOperator: String? = DeviceUtils.networkOperator
    let phoneType: Int? = DeviceUtils.phoneType
    let phoneCount: Int? = DeviceUtils.phoneCount
    let osVersion: String = DeviceUtils.osVersion
    let platform: String = DeviceUtils.platform

    enum CodingKeys: String, CodingKey {
        case ids = "ids"
        case name = "name"
        case bootCount = "boot_count"
        case locale = "locale"
        case carrier = "carrier"
        case networkOperator = "network_operator"
        case phoneType = "phone_type"
        case phoneCount = "phone_count"
        case osVersion = "os_version"
        case platform = "platform"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ids, forKey: .ids)
        try container.encode(name, forKey: .name)
        try container.encode(bootCount, forKey: .bootCount)
        try container.encode(locale, forKey: .locale)
        try container.encode(carrier, forKey: .carrier)
        try container.encode(networkOperator, forKey: .networkOperator)
        try container.encode(phoneType, forKey: .phoneType)
        try container.encode(phoneCount, forKey: .phoneCount)
        try container.encode(osVersion, forKey: .osVersion)
        try container.encode(platform, forKey: .platform)
    }
}
