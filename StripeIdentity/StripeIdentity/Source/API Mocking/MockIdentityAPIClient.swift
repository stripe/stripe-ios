//
//  MockIdentityAPIClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/4/21.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

/**
 Mock API client that returns responses from local JSON files instead of actual API endpoints.

 TODO(mludowise|IDPROD-2542): Delete this class when endpoints are live.
 */
class MockIdentityAPIClient {

    let verificationPageDataFileURL: URL
    let responseDelay: TimeInterval
    private(set) var displayErrorOnScreen: Int

    private var cachedVerificationPageDataResponse: VerificationPageData?

    private lazy var queue = DispatchQueue(label: "com.stripe.StripeIdentity.MockIdentityAPIClient", qos: .userInitiated)


    init(
        verificationPageDataFileURL: URL,
        displayErrorOnScreen: Int?,
        responseDelay: TimeInterval
    ) {
        self.verificationPageDataFileURL = verificationPageDataFileURL
        self.displayErrorOnScreen = displayErrorOnScreen ?? -1
        self.responseDelay = responseDelay
    }

    /**
     Generic helper to  mock API requests.
     - Parameters:
       - fileURL: JSON file to load response from
       - cachedResponse: If this file has already been loaded, use a cached response rather than re-loading it.
       - saveCachedResponse: Closure that saves the response fetched from the file system and updates the local cache.
       - transformResponse: Closure that transformes the fetched or cached response before returning it
     */
    private func mockRequest<ResponseType: StripeDecodable>(
        fileURL: URL,
        cachedResponse: ResponseType?,
        saveCachedResponse: @escaping (ResponseType) -> Void,
        transformResponse: ((ResponseType) -> ResponseType)? = nil
    ) -> Promise<ResponseType> {
        let transform: (ResponseType) -> ResponseType = { transformResponse?($0) ?? $0 }

        let promise = Promise<ResponseType>()
        queue.asyncAfter(deadline: .now() + responseDelay, execute: {

            // Return cached value if possible
            if let cachedResponse = cachedResponse {
                promise.resolve(with: transform(cachedResponse))
                return
            }

            do {
                let mockData = try Data(contentsOf: fileURL)
                let result: Result<ResponseType, Error> = STPAPIClient.decodeResponse(data: mockData, error: nil)

                switch result {
                case .success(let response):
                    saveCachedResponse(response)
                    promise.resolve(with: transform(response))
                case .failure(let error):
                    promise.reject(with: error)
                }
            } catch {
                promise.reject(with: error)
            }
        })
        return promise
    }

    /**
     Modify a mock response from the `VerificationPageData` endpoint such
     that missing requirements will naively contain the exact set of fields not
     yet input by the user.
     This method should only be used for mocking responses and will be removed when
     */
    static func modifyVerificationPageDataResponse(
        originalResponse: VerificationPageData,
        updating verificationData: VerificationPageDataUpdate,
        shouldDisplayError: Bool
    ) -> VerificationPageData {
        let requirementErrors = shouldDisplayError ? originalResponse.requirements.errors : []


        var missing = Set(VerificationPageRequirements.Missing.allCases)

        if verificationData.collectedData.consent?.biometric != nil {
            missing.remove(.biometricConsent)
        }
        if verificationData.collectedData.idDocument?.back != nil {
            missing.remove(.idDocumentBack)
        }
        if verificationData.collectedData.idDocument?.front != nil {
            missing.remove(.idDocumentFront)

            // If user is uploading passport, we wouldn't require a back photo
            if verificationData.collectedData.idDocument?.type == .passport {
                missing.remove(.idDocumentBack)
            }
        }
        if verificationData.collectedData.idDocument?.type != nil {
            missing.remove(.idDocumentType)
        }

        return .init(
            id: originalResponse.id,
            requirements: VerificationPageDataRequirements(
                errors: requirementErrors,
                missing: Array(missing),
                _allResponseFieldsStorage: nil
            ), status: originalResponse.status,
            submitted: originalResponse.submitted,
            _allResponseFieldsStorage: nil
        )
    }
}

extension MockIdentityAPIClient: IdentityAPIClient {
    func getIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPage> {
        return STPAPIClient.shared.getIdentityVerificationPage(id: id, ephemeralKeySecret: ephemeralKeySecret)
    }

    func updateIdentityVerificationPageData(
        id: String,
        updating verificationData: VerificationPageDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        let shouldDisplayError = displayErrorOnScreen == 0

        self.displayErrorOnScreen -= 1

        return mockRequest(
            fileURL: verificationPageDataFileURL,
            cachedResponse: cachedVerificationPageDataResponse,
            saveCachedResponse: { [weak self] response in
                self?.cachedVerificationPageDataResponse = response
            },
            transformResponse: { response in
                MockIdentityAPIClient.modifyVerificationPageDataResponse(
                    originalResponse: response,
                    updating: verificationData,
                    shouldDisplayError: shouldDisplayError
                )
            }
        )
    }

    func submitIdentityVerificationPage(
        id: String,
        ephemeralKeySecret: String
    ) -> Promise<VerificationPageData> {
        return STPAPIClient.shared.submitIdentityVerificationPage(id: id, ephemeralKeySecret: ephemeralKeySecret)
    }

    func uploadImage(
        _ image: UIImage,
        compressionQuality: CGFloat,
        purpose: String,
        fileName: String,
        ownedBy: String?,
        ephemeralKeySecret: String?
    ) -> Promise<StripeFile> {
        return STPAPIClient.shared.uploadImage(
            image,
            compressionQuality: compressionQuality,
            purpose: purpose,
            fileName: fileName,
            ownedBy: ownedBy,
            ephemeralKeySecret: ephemeralKeySecret
        )
    }
}
