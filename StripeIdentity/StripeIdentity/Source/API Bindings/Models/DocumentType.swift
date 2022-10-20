//
//  DocumentType.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//
import Foundation

enum DocumentType: String, Encodable, CaseIterable, Equatable {
    // NOTE: The declaration order determines the default order these
    // are displayed in the UI on the document selection screen
    case drivingLicense = "driving_license"
    case idCard = "id_card"
    case passport
}
