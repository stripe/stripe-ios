//
//  FCLiteError.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-19.
//

import Foundation

enum FCLiteError: Error {
    case linkedBankUnavailable
    case missingReturnURL
    case invalidReturnURL
    case authSessionCannotStart
    case authSessionFailedToStart
}
