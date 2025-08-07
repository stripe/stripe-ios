//
//  DocumentSide.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

enum DocumentSide: String {
    case front
    case back

    func instruction(availableIDTypes: [String]) -> String {

        func idDocument() -> String {
            if self == .front {
                return STPLocalizedString(
                    "Front of identity document",
                    "Title of ID document scanning screen when scanning the front of an identity card"
                )
            } else {
                return STPLocalizedString(
                    "Back of identity document",
                    "Title of ID document scanning screen when scanning the back of an identity card"
                )
            }
        }

        if availableIDTypes.count == 1 {
            let idType = availableIDTypes[0]

            if let type = idType.uiIDType() {
                switch self {
                case .front:
                    return String(format: STPLocalizedString("Front of %@", "Title of ID document scanning screen when scanning the front of either a driver's license, passport, or government issued photo id "), type)
                case .back:
                    return String(format: STPLocalizedString("Back of %@", "Title of ID document scanning screen when scanning the back of either a driver's license, passport, or government issued photo id"), type)
                }
            } else {
                return idDocument()
            }
        } else {
            return idDocument()

        }
    }
}
