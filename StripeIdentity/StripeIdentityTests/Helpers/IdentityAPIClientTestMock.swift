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
    }

    let verificationPage = MockAPIRequests<Void, VerificationPage>()
    let verificationPageData = MockAPIRequests<VerificationPageDataUpdate, VerificationPageData>()
    let verificationSessionSubmit = MockAPIRequests<Void, VerificationPageData>()
    let imageUpload = MockAPIRequests<ImageUploadRequestParams, StripeFile>()

    var verificationSessionId: String
    var ephemeralKeySecret: String

    init(
        verificationSessionId: String = "",
        ephemeralKeySecret: String = ""
    ) {
        self.verificationSessionId = verificationSessionId
        self.ephemeralKeySecret = ephemeralKeySecret
    }

    func getIdentityVerificationPage() -> Promise<VerificationPage> {
        return verificationPage.makeRequest(with: ())
    }

    func updateIdentityVerificationPageData(
        updating verificationData: VerificationPageDataUpdate
    ) -> Promise<VerificationPageData> {
        return verificationPageData.makeRequest(with: verificationData)
    }

    func submitIdentityVerificationPage() -> Promise<VerificationPageData> {
        return verificationSessionSubmit.makeRequest(with: ())
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) -> Promise<StripeFile> {
        return imageUpload.makeRequest(with: .init(
            image: image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName
        ))
    }
}

class MockAPIRequests<ParamsType, ResponseType> {
    private var requests: [Promise<ResponseType>] = []
    private(set) var requestHistory: [ParamsType] = []
    private var requestCallbacks: [(() -> Void)] = []

    fileprivate func makeRequest(with params: ParamsType) -> Promise<ResponseType> {
        requestHistory.append(params)
        let promise = Promise<ResponseType>()
        requests.append(promise)
        requestCallbacks.forEach { $0() }
        return promise
    }

    func respondToRequests(with result: Result<ResponseType, Error>) {
        requests.forEach { promise in
            promise.fullfill(with: result)
        }
    }

    func callBackOnRequest(_ block: @escaping () -> Void) {
        requestCallbacks.append(block)
    }
}
