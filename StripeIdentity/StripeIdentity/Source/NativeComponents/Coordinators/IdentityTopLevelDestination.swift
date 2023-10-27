//
//  IdentityTopLevelDestination.swift
//  StripeIdentity
//
//  Created by Chen Cen on 4/13/23.
//

import Foundation

enum IdentityTopLevelDestination {
    case consentDestination
    case docSelectionDestination
    case documentCaptureDestination(documentType: DocumentType)
    case selfieCaptureDestination
    case errorDestination
    case individualWelcomeDestination
    case individualDestination
    case confirmationDestination
    case phoneOtpDestination
}
