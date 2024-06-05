//
//  IdentityTopLevelDestination.swift
//  StripeIdentity
//
//  Created by Chen Cen on 4/13/23.
//

import Foundation

enum IdentityTopLevelDestination {
    case consentDestination
    case documentWarmupDestination
    case documentCaptureDestination
    case selfieCaptureDestination
    case errorDestination
    case individualWelcomeDestination
    case individualDestination
    case confirmationDestination
    case phoneOtpDestination
}
