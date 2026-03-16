//
//  KYCLevel.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 3/9/26.
//

import Foundation

/// Represents progressively stronger customer verification completeness.
enum KYCLevel {

    /// No information has been collected aside from email and phone, which are required for demo account creation.
    case none

    /// Name and address (plus email and phone, which are already required for demo account creation).
    case level0

    /// Level 0 fields + date of birth and id number (e.g. SSN).
    case level1

    /// Level 1 fields + id document verification.
    case level2

    /// Whether the receiver is level 0 or higher.
    var includesLevel0: Bool {
        switch self {
        case .none:
            return false
        case .level0, .level1, .level2:
            return true
        }
    }

    /// Whether the receiver is level 1 or higher.
    var includesLevel1: Bool {
        switch self {
        case .level1, .level2:
            return true
        case .none, .level0:
            return false
        }
    }

    var requiresDateOfBirthAndIdNumber: Bool {
        includesLevel1
    }

    var requiresIdentityDocumentCollection: Bool {
        switch self {
        case .level2:
            return true
        case .none, .level0, .level1:
            return false
        }
    }
}
