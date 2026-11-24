//
//  IdentityAPIClientTestMock.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 11/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
import UIKit
import XCTest

@testable import StripeIdentity

final class IdentityAPIClientTestMock: IdentityAPIClient {

    var apiVersion: Int = IdentityAPIClientImpl.productionApiVersion

    struct ImageUploadRequestParams {
        let image: UIImage
        let compressionQuality: CGFloat
        let purpose: String
        let fileName: String
    }

    let verificationPage = AsyncMockAPIRequests<Void, StripeAPI.VerificationPage>()
    let verificationPageData = AsyncMockAPIRequests<
        StripeAPI.VerificationPageDataUpdate, StripeAPI.VerificationPageData
    >()
    let verifyUnverifyRequest = AsyncMockAPIRequests<
        [String: Bool], StripeAPI.VerificationPageData
    >()
    let verificationSessionSubmit = AsyncMockAPIRequests<Void, StripeAPI.VerificationPageData>()
    let verificationPageGeneratePhoneOtp = AsyncMockAPIRequests<Void, StripeAPI.VerificationPageData>()
    let verificationPageCannotVerifyPhoneOtp = AsyncMockAPIRequests<Void, StripeAPI.VerificationPageData>()
    let imageUpload = AsyncMockAPIRequests<ImageUploadRequestParams, STPAPIClient.FileAndUploadMetrics>()

    var verificationSessionId: String
    var ephemeralKeySecret: String

    init(
        verificationSessionId: String = "",
        ephemeralKeySecret: String = ""
    ) {
        self.verificationSessionId = verificationSessionId
        self.ephemeralKeySecret = ephemeralKeySecret
    }

    func getIdentityVerificationPage() async throws -> StripeAPI.VerificationPage {
        try await verificationPage.makeRequest(with: ())
    }

    func updateIdentityVerificationPageData(
        updating verificationData: StripeAPI.VerificationPageDataUpdate
    ) async throws -> StripeAPI.VerificationPageData {
        try await verificationPageData.makeRequest(with: verificationData)
    }

    func submitIdentityVerificationPage() async throws -> StripeAPI.VerificationPageData {
        try await verificationSessionSubmit.makeRequest(with: ())
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String
    ) async throws -> STPAPIClient.FileAndUploadMetrics {
        try await imageUpload.makeRequest(
            with: .init(
                image: image,
                compressionQuality: compressionQuality,
                purpose: purpose,
                fileName: fileName
            )
        )
    }
    func verifyTestVerificationSession(simulateDelay: Bool) async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await verifyUnverifyRequest.makeRequest(with: ["simulateDelay": simulateDelay])
    }

    func unverifyTestVerificationSession(simulateDelay: Bool) async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await verifyUnverifyRequest.makeRequest(with: ["simulateDelay": simulateDelay])
    }

    func generatePhoneOtp() async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await verificationPageGeneratePhoneOtp.makeRequest(with: ())
    }

    func cannotPhoneVerifyOtp() async throws -> StripeCore.StripeAPI.VerificationPageData {
        try await verificationPageCannotVerifyPhoneOtp.makeRequest(with: ())
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

        let lock = NSLock()
        var uploadCount = 0

        self.imageUpload.callBackOnRequest {
            lock.lock()
            let currentUploadCount = uploadCount
            uploadCount += 1
            lock.unlock()

            guard currentUploadCount < count else {
                return XCTFail(
                    "Images were uploaded \(currentUploadCount + 1) times. Only expected \(count) times.",
                    file: file,
                    line: line
                )
            }
            expectations[currentUploadCount].fulfill()
        }

        return expectations
    }
}

class AsyncMockAPIRequests<ParamsType, ResponseType> {
    private let lock = NSLock()
    private var requests: [(params: ParamsType, continuation: CheckedContinuation<ResponseType, Error>)] = []
    private var _requestHistory: [ParamsType] = []
    private var requestCallbacks: [(() -> Void)] = []

    var requestHistory: [ParamsType] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return _requestHistory
    }

    fileprivate func makeRequest(with params: ParamsType) async throws -> ResponseType {
        return try await withCheckedThrowingContinuation { continuation in
            let callbacks: [() -> Void]
            lock.lock()
            _requestHistory.append(params)
            requests.append((params: params, continuation: continuation))
            callbacks = requestCallbacks
            lock.unlock()

            callbacks.forEach { $0() }
        }
    }

    func respondToRequests(with result: Result<ResponseType, Error>) {
        respondToRequests { _ in result }
    }

    /// Responds to each pending request with the result for its parameters. A nil result leaves the
    /// request pending.
    func respondToRequests(with result: (ParamsType) -> Result<ResponseType, Error>?) {
        var responses: [(continuation: CheckedContinuation<ResponseType, Error>, result: Result<ResponseType, Error>)] = []
        lock.lock()
        requests.removeAll { request in
            guard let requestResult = result(request.params) else { return false }
            responses.append((continuation: request.continuation, result: requestResult))
            return true
        }
        lock.unlock()

        responses.forEach { $0.continuation.resume(with: $0.result) }
    }

    func callBackOnRequest(_ block: @escaping () -> Void) {
        lock.lock()
        requestCallbacks.append(block)
        lock.unlock()
    }
}
