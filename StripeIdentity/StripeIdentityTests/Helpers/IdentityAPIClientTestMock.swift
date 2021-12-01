//
//  IdentityAPIClientTestMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/4/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class IdentityAPIClientTestMock: IdentityAPIClient {

    let verificationPage = MockAPIRequests<(id: String, ephemeralKey: String), VerificationPage>()
    let verificationPageData = MockAPIRequests<(id: String, data: VerificationPageDataUpdate, ephemeralKey: String), VerificationPageData>()
    let verificationSessionSubmit = MockAPIRequests<(id: String, ephemeralKey: String), VerificationPageData>()
    let imageUpload = MockAPIRequests<(image: UIImage, purpose: StripeFile.Purpose), StripeFile>()

    func getIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPage> {
        return verificationPage.makeRequest(with: (
            id: id,
            ephemeralKey: ephemeralKeySecret
        ))
    }

    func updateIdentityVerificationPageData(
        id: String,
        updating verificationData: VerificationPageDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        return verificationPageData.makeRequest(with: (
            id: id,
            data: verificationData,
            ephemeralKey: ephemeralKeySecret
        ))
    }

    func submitIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        return verificationSessionSubmit.makeRequest(with: (
            id: id,
            ephemeralKey: ephemeralKeySecret
        ))
    }

    func uploadImage(_ image: UIImage, purpose: StripeFile.Purpose) -> Promise<StripeFile> {
        return imageUpload.makeRequest(with: (image, purpose))
    }
}

class MockAPIRequests<ParamsType, ResponseType> {
    private var requests: [Promise<ResponseType>] = []
    private(set) var requestHistory: [ParamsType] = []

    fileprivate func makeRequest(with params: ParamsType) -> Promise<ResponseType> {
        requestHistory.append(params)
        let promise = Promise<ResponseType>()
        requests.append(promise)
        return promise
    }

    func respondToRequests(with result: Result<ResponseType, Error>) {
        requests.forEach { promise in
            promise.fullfill(with: result)
        }
    }
}
