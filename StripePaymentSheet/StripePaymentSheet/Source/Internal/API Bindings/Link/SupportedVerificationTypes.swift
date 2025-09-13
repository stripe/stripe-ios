//
//  SupportedVerificationTypes.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 9/12/25.
//

import Foundation

// Add new cases here whenever they are supported.
// String values should map to those in zoolander/../common.proto/VerificationType
enum SupportedVerificationType: String, CaseIterable {
    case sms = "SMS"
}
