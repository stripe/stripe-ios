//
//  IdentityAPIClientTestMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/4/21.
//

import Foundation
import UIKit
import XCTest
@_spi(STP) import StripeCore
@testable import StripeIdentity

final class IdentityAPIClientTestMock: IdentityAPIClient {

    var apiVersion: Int = IdentityAPIClientImpl.productionApiVersion

    struct ImageUploadRequestParams {
        let image: UIImage
        let compressionQuality: CGFloat
        let purpose: String
        let fileName: String
    }

    let verificationPage = MockAPIRequests<Void, StripeAPI.VerificationPage>()
    let verificationPageData = MockAPIRequests<StripeAPI.VerificationPageDataUpdate, StripeAPI.VerificationPageData>()
    let verificationSessionSubmit = MockAPIRequests<Void, StripeAPI.VerificationPageData>()
    let imageUpload = MockAPIRequests<ImageUploadRequestParams, STPAPIClient.FileAndUploadMetrics>()

    var verificationSessionId: String
    var ephemeralKeySecret: String

    init(
        verificationSessionId: String = "",
        ephemeralKeySecret: String = ""
    ) {
        self.verificationSessionId = verificationSessionId
        self.ephemeralKeySecret = ephemeralKeySecret
    }

    func getIdentityVerificationPage() -> Promise<StripeAPI.VerificationPage> {
        return verificationPage.makeRequest(with: ())
    }

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) -> Promise<StripeAPI.VerificationPageData> {
        return verificationPageData.makeRequest(with: verificationData)
    }

    func submitIdentityVerificationPage() -> Promise<StripeAPI.VerificationPageData> {
        return verificationSessionSubmit.makeRequest(with: ())
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) -> Future<STPAPIClient.FileAndUploadMetrics> {
        return imageUpload.makeRequest(with: .init(
            image: image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName
        ))
    }

    // Ensures `count` number of files are uploaded
    func makeUploadRequestExpectations(
        count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [XCTestExpectation] {
        var expectations: [XCTestExpectation] = []
        expectations.reserveCapacity(count)
        (1...count).forEach { expectations.append(.init(description: "Uploaded image \($0)")) }

        var uploadCount = 0

        self.imageUpload.callBackOnRequest {
            // Increment uploadCount last
            defer {
                uploadCount += 1
            }
            guard uploadCount < count else {
                return XCTFail("Images were uploaded \(uploadCount+1) times. Only expected \(count) times.", file: file, line: line)
            }
            expectations[uploadCount].fulfill()
        }

        return expectations
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
