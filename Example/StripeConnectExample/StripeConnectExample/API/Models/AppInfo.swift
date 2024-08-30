//
//  AppInfo.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/23/24.
//

import Foundation

struct AppInfo: Codable {
    let publishableKey: String
    let availableMerchants: [MerchantInfo]
}

struct MerchantInfo: Codable, Identifiable, Equatable {
    var id: String {
        merchantId
    }
    let displayName: String?
    let merchantId: String
}
