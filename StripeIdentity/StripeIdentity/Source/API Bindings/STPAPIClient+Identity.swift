//
//  STPAPIClient+Identity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/26/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

protocol IdentityAPIClient {
    func createIdentityVerificationPage(
        clientSecret: String
    ) -> Promise<VerificationPage>

    func updateIdentityVerificationSessionData(
        id: String,
        updating verificationData: VerificationSessionDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData>

    func submitIdentityVerificationSession(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData>

    func uploadImage(
        _ image: UIImage,
        purpose: StripeFile.Purpose
    ) -> Promise<StripeFile>
}

extension STPAPIClient: IdentityAPIClient {
    func createIdentityVerificationPage(
        clientSecret: String
    ) -> Promise<VerificationPage> {
        return self.post(
            resource: APIEndpointVerificationPage,
            parameters: ["client_secret": clientSecret]
        )
    }

    func updateIdentityVerificationSessionData(
        id: String,
        updating verificationData: VerificationSessionDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData> {
        return self.post(
            resource: APIEndpointVerificationSessionData(id: id),
            object: verificationData,
            ephemeralKeySecret: ephemeralKeySecret
        )
    }

    func submitIdentityVerificationSession(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData> {
        return self.post(
            resource: APIEndpointVerificationSessionSubmit(id: id),
            parameters: [:],
            ephemeralKeySecret: ephemeralKeySecret
        )
    }
}

private let APIEndpointVerificationPage = "identity/verification_pages"
private func APIEndpointVerificationSessionData(id: String) -> String {
    return "identity/verification_sessions/\(id)/data"
}
private func APIEndpointVerificationSessionSubmit(id: String) -> String {
    return "identity/verification_sessions/\(id)/submit"
}
