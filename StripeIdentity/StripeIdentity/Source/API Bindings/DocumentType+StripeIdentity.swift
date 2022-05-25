//
//  DocumentType+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/11/22.
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
