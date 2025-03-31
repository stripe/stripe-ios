//
//  FCLiteManifest.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation

struct SynchronizePayload: Decodable {
    let manifest: LinkAccountSessionManifest
}

struct LinkAccountSessionManifest: Decodable {
    let id: String

    let hostedAuthURL: URL
    let successURL: URL
    let cancelURL: URL

    private let product: String
    private let manualEntryUsesMicrodeposits: Bool

    var isInstantDebits: Bool {
        product == "instant_debits"
    }
    var bankAccountIsInstantlyVerified: Bool {
        !manualEntryUsesMicrodeposits
    }

    enum CodingKeys: String, CodingKey {
        case id
        case hostedAuthURL = "hosted_auth_url"
        case successURL = "success_url"
        case cancelURL = "cancel_url"
        case product
        case manualEntryUsesMicrodeposits = "manual_entry_uses_microdeposits"
    }
}
