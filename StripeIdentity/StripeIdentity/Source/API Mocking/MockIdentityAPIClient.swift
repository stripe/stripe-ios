//
//  MockIdentityAPIClient.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/4/21.
//

import Foundation
@_spi(STP) import StripeCore

/**
 Mock API client that returns responses from local JSON files instead of actual API endpoints.

 TODO(mludowise|IDPROD-2542): Delete this class when endpoints are live.
 */
class MockIdentityAPIClient {

    let verificationPageFileURL: URL
    let verificationSessionDataFileURL: URL
    let responseDelay: TimeInterval
    private(set) var displayErrorOnScreen: Int

    private var cachedVerificationPageResponse: VerificationPage?
    private var cachedVerificationSessionDataResponse: VerificationSessionData?

    private lazy var queue = DispatchQueue(label: "com.stripe.StripeIdentity.MockIdentityAPIClient", qos: .userInitiated)


    init(
        verificationPageFileURL: URL,
        verificationSessionDataFileURL: URL,
        displayErrorOnScreen: Int?,
        responseDelay: TimeInterval
    ) {
        self.verificationPageFileURL = verificationPageFileURL
        self.verificationSessionDataFileURL = verificationSessionDataFileURL
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
     Modify a mock response from the `VerificationSessionData` endpoint such
     that missing requirements will naively contain the exact set of fields not
     yet input by the user.
     This method should only be used for mocking responses and will be removed when
     */
    static func modifyVerificationSessionDataResponse(
        originalResponse: VerificationSessionData,
        updating verificationData: VerificationSessionDataUpdate,
        shouldDisplayError: Bool
    ) -> VerificationSessionData {
        let requirementErrors = shouldDisplayError ? originalResponse.requirements.errors : []


        var missing = Set(VerificationPageRequirements.Missing.allCases)

        if verificationData.collectedData.individual.address != nil {
            missing.remove(.address)
        }
        if verificationData.collectedData.individual.consent?.biometric != nil {
            missing.remove(.biometricConsent)
        }
        if verificationData.collectedData.individual.dob != nil {
            missing.remove(.dob)
        }
        if verificationData.collectedData.individual.email != nil {
            missing.remove(.email)
        }
        if verificationData.collectedData.individual.face != nil {
            missing.remove(.face)
        }
        if verificationData.collectedData.individual.idDocument?.back != nil {
            missing.remove(.idDocumentBack)
        }
        if verificationData.collectedData.individual.idDocument?.front != nil {
            missing.remove(.idDocumentFront)
        }
        if verificationData.collectedData.individual.idDocument?.type != nil {
            missing.remove(.idDocumentType)
        }
        if verificationData.collectedData.individual.idNumber != nil {
            missing.remove(.idNumber)
        }
        if verificationData.collectedData.individual.name != nil {
            missing.remove(.name)
        }
        if verificationData.collectedData.individual.phoneNumber != nil {
            missing.remove(.phoneNumber)
        }
        if verificationData.collectedData.individual.consent?.train != nil {
            missing.remove(.trainingConsent)
        }

        return .init(
            id: originalResponse.id,
            status: originalResponse.status,
            submitted: originalResponse.submitted,
            requirements: VerificationSessionDataRequirements(
                missing: Array(missing),
                errors: requirementErrors,
                _allResponseFieldsStorage: nil
            ),
            _allResponseFieldsStorage: nil
        )
    }
}

extension MockIdentityAPIClient: IdentityAPIClient {
    func postIdentityVerificationPage(clientSecret: String) -> Promise<VerificationPage> {
        return mockRequest(
            fileURL: verificationPageFileURL,
            cachedResponse: cachedVerificationPageResponse,
            saveCachedResponse: { [weak self] response in
                self?.cachedVerificationPageResponse = response
            }
        )
    }

    func postIdentityVerificationSessionData(
        id: String,
        updating verificationData: VerificationSessionDataUpdate,
        ephemeralKeySecret: String
    ) -> Promise<VerificationSessionData> {
        let shouldDisplayError = displayErrorOnScreen == 0

        self.displayErrorOnScreen -= 1

        return mockRequest(
            fileURL: verificationSessionDataFileURL,
            cachedResponse: cachedVerificationSessionDataResponse,
            saveCachedResponse: { [weak self] response in
                self?.cachedVerificationSessionDataResponse = response
            },
            transformResponse: { response in
                MockIdentityAPIClient.modifyVerificationSessionDataResponse(
                    originalResponse: response,
                    updating: verificationData,
                    shouldDisplayError: shouldDisplayError
                )
            }
        )
    }
}
