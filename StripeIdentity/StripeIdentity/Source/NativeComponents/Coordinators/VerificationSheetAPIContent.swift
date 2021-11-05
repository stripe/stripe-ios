//
//  VerificationSheetAPIContent.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/3/21.
//

import Foundation
@_spi(STP) import StripeCore

/**
 Data structure that joins:

 - `VerificationPage`: Static content fetched once before the VerificationSheet
    is presented to the user.

 – `VerificationSessionData`: Updated any time the user's data is saved to the
    server from the server response.

 Values for common fields should be determined by first checking the session
 data, since it's always more up-to-date, before defaulting to static content.
 */
struct VerificationSheetAPIContent {
    /// Static content to display to the user during the verification process
    private(set) var staticContent: VerificationPage? = nil

    /// Server response from the last time the user's data was saved
    private(set) var sessionData: VerificationSessionData? = nil

    private(set) var lastError: Error? = nil

    /// Status of the associated VerificationSession.
    var status: VerificationPage.Status? {
        return sessionData?.status ?? staticContent?.status
    }

    /// If true, the associated VerificationSession has been submitted for processing.
    var submitted: Bool? {
        return sessionData?.submitted ?? staticContent?.submitted
    }

    /// Contains the fields that need to be collected
    var missingRequirements: Set<VerificationPageRequirements.Missing>? {
        return (sessionData?.requirements.missing ?? staticContent?.requirements.missing).map { Set($0) }
    }

    /// Errors specific to data entered by the user
    var requiredDataErrors: [VerificationSessionDataRequirementError] {
        return sessionData?.requirements.errors ?? []
    }

    /// Updates the static content after the `VerificationPage` response has returned
    mutating func setStaticContent(result: Result<VerificationPage, Error>) {
        switch result {
        case .success(let verificationPage):
            self.staticContent = verificationPage
        case .failure(let error):
            self.lastError = error
        }
    }

    /// Updates the static content after the `VerificationSessionData` response has returned
    mutating func setSessionData(result: Result<VerificationSessionData, Error>) {
        switch result {
        case .success(let verificationSessionData):
            self.sessionData = verificationSessionData
        case .failure(let error):
            self.lastError = error
        }
    }
}
