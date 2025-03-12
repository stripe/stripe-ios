//
//  Manifest.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-12.
//

import Foundation

struct SynchronizePayload: Decodable {
    let manifest: LinkAccountSessionManifest
}

struct LinkAccountSessionManifest: Decodable {
    let id: String
    let product: String

    let hostedAuthURL: URL
    let successURL: URL
    let cancelURL: URL

    var isInstantDebits: Bool {
        product == "instant_debits"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case product
        case hostedAuthURL = "hosted_auth_url"
        case successURL = "success_url"
        case cancelURL = "cancel_url"
    }
}
