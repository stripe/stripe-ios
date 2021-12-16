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

    struct ImageUploadRequestParams {
        let image: UIImage
        let compressionQuality: CGFloat
        let purpose: String
        let fileName: String
        let ownedBy: String?
        let ephemeralKeySecret: String?
    }

    let verificationPage = MockAPIRequests<(id: String, ephemeralKey: String), VerificationPage>()
    let verificationPageData = MockAPIRequests<(id: String, data: VerificationPageDataUpdate, ephemeralKey: String), VerificationPageData>()
    let verificationSessionSubmit = MockAPIRequests<(id: String, ephemeralKey: String), VerificationPageData>()
    let imageUpload = MockAPIRequests<ImageUploadRequestParams, StripeFile>()

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

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String,
        ownedBy: String?,
        ephemeralKeySecret: String?
    ) -> Promise<StripeFile> {
        return imageUpload.makeRequest(with: .init(
            image: image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: ownedBy,
            ephemeralKeySecret: ephemeralKeySecret
        ))
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
