//
//  NetworkedIdentityDocumentRequirements.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

struct NetworkedIdentityDocumentRequirements: Equatable {
    let allowedDocumentTypes: [NetworkedIdentityDocumentType]
    let requiresLiveCapture: Bool

    init(
        allowedDocumentTypes: [NetworkedIdentityDocumentType],
        requiresLiveCapture: Bool
    ) {
        self.allowedDocumentTypes = allowedDocumentTypes
        self.requiresLiveCapture = requiresLiveCapture
    }

    init(verificationPage: StripeAPI.VerificationPage) {
        allowedDocumentTypes = verificationPage.documentSelect.idDocumentTypeAllowlistKeys
            .compactMap(NetworkedIdentityDocumentType.init(rawValue:))
        requiresLiveCapture = verificationPage.documentCapture.requireLiveCapture
    }

    func allows(
        _ document: NetworkedIdentityDocument,
        at currentTime: TimeInterval
    ) -> Bool {
        document.documentType != .unparsable
            && allowedDocumentTypes.contains(document.documentType)
            && (!requiresLiveCapture || document.liveCaptured == true)
            && document.expirationDate.map { TimeInterval($0) > currentTime } != false
    }
}
