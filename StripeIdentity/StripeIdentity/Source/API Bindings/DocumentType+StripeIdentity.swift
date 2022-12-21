//
//  DocumentType+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension DocumentType {
    var hasBack: Bool {
        switch self {
        case .passport:
            return false
        case .drivingLicense,
            .idCard:
            return true
        }
    }
}
