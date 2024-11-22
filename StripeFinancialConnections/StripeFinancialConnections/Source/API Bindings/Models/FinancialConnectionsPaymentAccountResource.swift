//
//  FinancialConnectionsPaymentAccountResource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

typealias MicrodepositVerificationMethod = FinancialConnectionsPaymentAccountResource.MicrodepositVerificationMethod
struct FinancialConnectionsPaymentAccountResource: Decodable {

    enum MicrodepositVerificationMethod: String, SafeEnumCodable, Equatable {
        case descriptorCode = "descriptor_code"
        case amounts = "amounts"
        case unparsable
    }

    let id: String
    let nextPane: FinancialConnectionsSessionManifest.NextPane?
    let microdepositVerificationMethod: MicrodepositVerificationMethod?
    let networkingSuccessful: Bool?
}
