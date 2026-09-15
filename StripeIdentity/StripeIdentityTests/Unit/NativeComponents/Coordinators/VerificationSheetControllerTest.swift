//
//  VerificationSheetControllerTest.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
import UIKit
import XCTest

@testable import StripeIdentity

final class VerificationSheetControllerTest: XCTestCase {

    let mockVerificationSessionId = "vs_123"
    let mockEphemeralKeySecret = "sk_test_123"

    private var mockFlowController: VerificationSheetFlowControllerMock!
    private var controller: VerificationSheetController!
    private var mockAPIClient: IdentityAPIClientTestMock!
    // swiftlint:disable:next weak_delegate
    private var mockDelegate: MockDelegate!
    private var mockMLModelLoader: IdentityMLModelLoaderMock!
    private var mockAnalyticsClient: MockAnalyticsClientV2!
    private var identityAnalyticsClient: IdentityAnalyticsClient!
    private var exp: XCTestExpectation!
    private var mockDocumentUploader: DocumentUploaderMock!

    override func setUp() {
        super.setUp()

        mockDocumentUploader = DocumentUploaderMock()
        // Mock the api client
        mockAPIClient = IdentityAPIClientTestMock(
            verificationSessionId: mockVerificationSessionId,
            ephemeralKeySecret: mockEphemeralKeySecret
        )
        mockDelegate = MockDelegate()
        mockMLModelLoader = IdentityMLModelLoaderMock()
        mockFlowController = VerificationSheetFlowControllerMock()
        mockFlowController.documentUploader = mockDocumentUploader
        mockAnalyticsClient = MockAnalyticsClientV2()
        identityAnalyticsClient = .init(
            verificationSessionId: "",
            analyticsClient: mockAnalyticsClient
        )
        controller = VerificationSheetController(
            apiClient: mockAPIClient,
            flowController: mockFlowController,
            mlModelLoader: mockMLModelLoader,
            analyticsClient: identityAnalyticsClient
        )
        controller.delegate = mockDelegate
        exp = XCTestExpectation(description: "Finished API call")
    }

    func testLoadValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200.make()

        // Load
        controller.load().observe { _ in
            self.exp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify result is nil until API responds to request
        XCTAssertNil(controller.verificationPageResponse)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(try? controller.verificationPageResponse?.get(), mockResponse)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingFaceModels)
    }

    func testNetworkedIdentityResultPreservesAttachedFilesOnLaterUpdates() throws {
        // Given document and selfie requirements were satisfied by an NI attachment
        let page = try VerificationPageMock.response200.make().copyWithNewMissings(
            newMissings: [.biometricConsent, .idDocumentFront, .idDocumentBack, .face, .phoneOtp]
        )
        controller.verificationPageResponse = .success(page)
        controller.collectedData = .init(biometricConsent: true, phoneOtp: "old-code")
        let result = try VerificationPageDataMock.noErrorsWithMissings(with: [.phoneOtp])

        // When the server response is handed back to the ordinary Identity flow
        controller.continueAfterNetworkedIdentity(with: .success(result)) { self.exp.fulfill() }
        wait(for: [exp], timeout: 1)

        // Then stale missing values are cleared, but valid local consent is retained
        XCTAssertNil(controller.collectedData.phoneOtp)
        XCTAssertEqual(controller.collectedData.biometricConsent, true)
        XCTAssertEqual(try controller.verificationPageResponse?.get().requirements.missing, [.phoneOtp])
        XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
        XCTAssertFalse(controller.isVerificationPageSubmitted)

        // ...and collecting the remaining field does not clear the server-owned images
        controller.saveAndTransition(from: .phoneOtp, collectedData: .init(phoneOtp: "123456"), completion: {})
        let clearData = try XCTUnwrap(mockAPIClient.verificationPageData.requestHistory.last?.clearData)
        XCTAssertEqual(clearData.idDocumentFront, false)
        XCTAssertEqual(clearData.idDocumentBack, false)
        XCTAssertEqual(clearData.face, false)
        XCTAssertEqual(clearData.biometricConsent, false)
    }

    func testSharedDocumentKeepsTheAttachmentWhenRecordingConsent() throws {
        // Given the consent screen still lists the document as missing
        let page = try VerificationPageMock.response200.make().copyWithNewMissings(
            newMissings: [.biometricConsent, .idDocumentFront, .idDocumentBack, .face]
        )
        controller.verificationPageResponse = .success(page)
        let attached = try VerificationPageDataMock.noErrorsWithMissings(with: [.biometricConsent, .face])

        // When the user shares a saved ID from Link
        controller.saveConsentAfterNetworkedIdentity(attached: attached, completion: {})

        // Then consent is recorded without clearing the attached document
        let request = try XCTUnwrap(mockAPIClient.verificationPageData.requestHistory.last)
        XCTAssertEqual(request.collectedData?.biometricConsent, true)
        XCTAssertEqual(request.clearData?.idDocumentFront, false)
        XCTAssertEqual(request.clearData?.idDocumentBack, false)
        XCTAssertEqual(try controller.verificationPageResponse?.get().requirements.missing, [.biometricConsent, .face])
    }

    func testNetworkedIdentityEmptyRequirementsSubmitBeforeSuccess() throws {
        // Given attach or resume has no remaining fields but has not submitted the VS
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())
        let result = try VerificationPageDataMock.noErrors.make()

        // When NI completes, it must go through the existing submit API
        controller.continueAfterNetworkedIdentity(with: .success(result)) { self.exp.fulfill() }
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        XCTAssertFalse(controller.isVerificationPageSubmitted)
        XCTAssertNil(mockFlowController.transitionedWithUpdateDataResult)

        // Then completion is only reported after the submit response
        let submitted = try VerificationPageDataMock.submitted.make()
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(submitted))
        wait(for: [exp], timeout: 1)
        XCTAssertTrue(controller.isVerificationPageSubmitted)
        XCTAssertEqual(try mockFlowController.transitionedWithUpdateDataResult?.get(), submitted)
    }

    func testRecordingCommittedNetworkedIdentityRequirementsDoesNotAdvanceTheUI() throws {
        let page = try VerificationPageMock.response200.make()
        controller.verificationPageResponse = .success(page)
        let updated = StripeAPI.VerificationPageData(
            id: page.id, requirements: .init(errors: [], missing: [.biometricConsent, .face]),
            status: .requiresInput, submitted: false, closed: false
        )

        controller.recordNetworkedIdentityUpdate(updated)

        XCTAssertEqual(try controller.verificationPageResponse?.get().requirements.missing, [.biometricConsent, .face])
        XCTAssertNil(mockFlowController.transitionedWithUpdateDataResult)
        XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
    }

    func testNetworkedIdentityValidationErrorDoesNotSubmitOrReplaceRequirements() throws {
        // Given the backend rejected the mutation
        let page = try VerificationPageMock.response200.make()
        controller.verificationPageResponse = .success(page)
        let result = try VerificationPageDataMock.response200.make()
        XCTAssertFalse(result.requirements.errors.isEmpty)

        // When the response returns to the host
        controller.continueAfterNetworkedIdentity(with: .success(result)) { self.exp.fulfill() }
        wait(for: [exp], timeout: 1)

        // Then it is routed as an error without a submit or fabricated state change
        XCTAssertEqual(try controller.verificationPageResponse?.get(), page)
        XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
        XCTAssertFalse(controller.isVerificationPageSubmitted)
        XCTAssertEqual(try mockFlowController.transitionedWithUpdateDataResult?.get(), result)
    }

    func testNetworkedIdentityRequestFailureDoesNotSubmit() throws {
        let page = try VerificationPageMock.response200.make()
        controller.verificationPageResponse = .success(page)
        let error = NSError(domain: "NetworkedIdentityTest", code: 1)

        controller.continueAfterNetworkedIdentity(with: .failure(error)) { self.exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(try controller.verificationPageResponse?.get(), page)
        XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
        XCTAssertFalse(controller.isVerificationPageSubmitted)
        guard case .failure(let receivedError) = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected the NI request error")
        }
        XCTAssertEqual(receivedError as NSError, error)
    }

    func testNetworkedIdentityAlreadySubmittedResultDoesNotResubmit() throws {
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())
        let result = try VerificationPageDataMock.submitted.make()

        controller.continueAfterNetworkedIdentity(with: .success(result)) { self.exp.fulfill() }
        wait(for: [exp], timeout: 1)

        XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
        XCTAssertTrue(controller.isVerificationPageSubmitted)
        XCTAssertEqual(try mockFlowController.transitionedWithUpdateDataResult?.get(), result)
    }

    func testNetworkedIdentityRejectsCanceledOrUnwritableSessions() throws {
        let cases: [(StripeAPI.VerificationPage.Status, Bool, Bool)] = [
            (.canceled, false, false),
            (.canceled, true, true),
            (.requiresInput, false, true),
            (.processing, false, false),
            (.verified, false, false),
            (.requiresInput, true, false),
        ]
        for (status, submitted, closed) in cases {
            // Given an action response is not writable and is not a valid completed flow
            let page = try VerificationPageMock.response200.make()
            let flow = VerificationSheetFlowControllerMock()
            let sheet = VerificationSheetController(
                apiClient: mockAPIClient,
                flowController: flow,
                mlModelLoader: mockMLModelLoader,
                analyticsClient: identityAnalyticsClient
            )
            sheet.verificationPageResponse = .success(page)
            let response = StripeAPI.VerificationPageData(
                id: page.id, requirements: .init(errors: [], missing: []),
                status: status, submitted: submitted, closed: closed
            )

            // When a background write or a visible NI flow hands the response to the host
            sheet.recordNetworkedIdentityUpdate(response)
            sheet.continueAfterNetworkedIdentity(with: .success(response), completion: {})

            // Then there is no write, fabricated success, or cached-requirements change
            XCTAssertTrue(mockAPIClient.verificationSessionSubmit.requestHistory.isEmpty)
            XCTAssertFalse(sheet.isVerificationPageSubmitted)
            XCTAssertEqual(try sheet.verificationPageResponse?.get(), page)
            guard case .failure = flow.transitionedWithUpdateDataResult else {
                return XCTFail("Expected a terminal state error for \(status)")
            }
        }
    }

    func testLoadSubmittedValidResponse() throws {
        let mockResponse = try VerificationPageMock.response200Submitted.make()

        // Load
        controller.load().observe { _ in
            self.exp.fulfill()
        }

        // Verify 1 request made with secret
        XCTAssertEqual(mockAPIClient.verificationPage.requestHistory.count, 1)

        // Verify result is nil until API responds to request
        XCTAssertNil(controller.verificationPageResponse)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify response updated on controller
        XCTAssertEqual(try? controller.verificationPageResponse?.get(), mockResponse)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingDocumentModels)
        XCTAssertTrue(mockMLModelLoader.didStartLoadingFaceModels)
        XCTAssertTrue(controller.isVerificationPageSubmitted)
    }

    func testLoadErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Load
        controller.load().observe { _ in
            self.exp.fulfill()
        }

        // Respond to request with error
        mockAPIClient.verificationPage.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify error updated on controller
        guard case .failure = controller.verificationPageResponse else {
            return XCTFail("Expected failure")
        }
    }

    func testLoadAndUpdateUI() throws {
        let mockResponse = try VerificationPageMock.response200.make()
        controller.loadAndUpdateUI(skipTestMode: true)

        // Respond to request with success
        mockAPIClient.verificationPage.respondToRequests(with: .success(mockResponse))

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithStaticContentResult?.get(),
            mockResponse
        )
    }

    func testSaveDataValidResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockResponse = try VerificationPageDataMock.noErrors.make()
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        mockFlowController.uncollectedFields = [.idDocumentFront, .idDocumentBack]

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify 1 request made with Id, EAK, and collected data
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first,
            .init(
                clearData: .init(
                    biometricConsent: false,
                    face: true,
                    idDocumentBack: true,
                    idDocumentFront: true,
                    idNumber: false,
                    dob: false,
                    name: false,
                    address: false,
                    phoneOtp: false
                ),
                collectedData: mockData
            )
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData.biometricConsent, true)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockResponse
        )
    }

    func testSaveDataErrorResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)
        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Respond to request with failure
        mockAPIClient.verificationPageData.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value not cached locally
        XCTAssertNil(controller.collectedData.biometricConsent)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentFrontNotNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let notNeedbackExp = expectation(description: "onNotNeedback is called")
        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { isBackRequired in
                if !isBackRequired {
                    notNeedbackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))
        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [notNeedbackExp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testForceDocumentFrontNotNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let notNeedbackExp = expectation(description: "onNotNeedback is called")

        controller.forceDocumentFrontAndDecideBack(
            from: .biometricConsent,
            onCompletion: { isBackRequired in
                if !isBackRequired {
                    notNeedbackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))
        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [notNeedbackExp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData.withForceConfirm(true))

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentFrontNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrorsNeedback.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let needBackExp = expectation(description: "onNeedBack is called")
        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { isBackRequired in
                if isBackRequired {
                    needBackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [needBackExp], timeout: 1)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData)
    }

    func testForceDocumentFrontNeedbackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let frontFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentFront)!

        let mockResponse = try VerificationPageDataMock.noErrorsNeedback.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        let needBackExp = expectation(description: "onNeedBack is called")
        controller.forceDocumentFrontAndDecideBack(
            from: .biometricConsent,
            onCompletion: { isBackRequired in
                if isBackRequired {
                    needBackExp.fulfill()
                }
            }
        )

        // Mock that document upload succeeded
        mockDocumentUploader.frontUploadPromise.resolve(with: frontFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentFront,
            frontFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [needBackExp], timeout: 1)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, frontFileData.withForceConfirm(true))
    }

    func testSaveDocumentFrontFailure() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        controller.saveDocumentFrontAndDecideBack(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader,
            onCompletion: { _ in }
        )
        // Mock that document upload failed
        mockDocumentUploader.frontUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentFront, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDocumentBackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        controller.saveDocumentBackAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {
            self.exp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.backUploadPromise.resolve(with: backFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentBack,
            backFileData
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, backFileData)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testForceDocumentBackSuccess() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let backFileData = (VerificationPageDataUpdateMock.default.collectedData?.idDocumentBack)!

        let mockResponse = try VerificationPageDataMock.noErrors.make()

        let saveRequestExp = expectation(description: "Save data request was made")
        mockAPIClient.verificationPageData.callBackOnRequest {
            saveRequestExp.fulfill()
        }

        controller.forceDocumentBackAndTransition(
            from: .biometricConsent
        ) {
            self.exp.fulfill()
        }

        // Mock that document upload succeeded
        mockDocumentUploader.backUploadPromise.resolve(with: backFileData)

        // Verify save data request was made
        wait(for: [saveRequestExp], timeout: 1)
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 1)
        XCTAssertEqual(
            mockAPIClient.verificationPageData.requestHistory.first?.collectedData?.idDocumentBack,
            backFileData.withForceConfirm(true)
        )

        // Respond to request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .success(mockResponse))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify analytics client updated
        XCTAssertEqual(identityAnalyticsClient.timeToScreenFromScreen, .biometricConsent)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, backFileData.withForceConfirm(true))

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
    }

    func testSaveDocumentBackFailure() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        controller.saveDocumentBackAndTransition(
            from: .biometricConsent,
            documentUploader: mockDocumentUploader
        ) {}

        // Mock that document upload failed
        mockDocumentUploader.backUploadPromise.reject(with: mockError)

        // Verify values cached locally
        XCTAssertEqual(controller.collectedData.idDocumentBack, nil)

        // Verify save data request was not made
        XCTAssertEqual(mockAPIClient.verificationPageData.requestHistory.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testSaveDataSubmitsValidResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockDataResponse = try VerificationPageDataMock.noErrors.make()
        let mockSubmitResponse = try VerificationPageDataMock.submitted.make()
        let mockData = VerificationPageDataUpdateMock.default.collectedData!

        // Mock number of attempted scans
        controller.analyticsClient.countDidStartDocumentScan(for: .front)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockDataResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(
            with: .success(mockSubmitResponse)
        )

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify value cached locally
        XCTAssertEqual(controller.collectedData, mockData)

        // Verify submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, true)

        // Verify succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 1)
        let analytic = mockAnalyticsClient.loggedAnalyticsPayloads.first
        XCTAssert(
            analytic: analytic,
            hasProperty: "event_name",
            withValue: "verification_succeeded"
        )
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_model_score", withValue: Float(1))
        XCTAssert(analytic: analytic, hasMetadata: "selfie_model_score", withValue: Float(0.9))
        XCTAssert(analytic: analytic, hasMetadata: "doc_front_retry_times", withValue: 0)
        XCTAssert(analytic: analytic, hasMetadata: "doc_back_retry_times", withValue: 1)
        XCTAssert(analytic: analytic, hasMetadata: "selfie_retry_times", withValue: 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockSubmitResponse
        )
    }

    func testSaveDataSubmitsFallbackResponse() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockDataResponse = try VerificationPageDataMock.noErrors.make()
        let mockSubmitResponse = try VerificationPageDataMock.submittedNotClosed.make()
        let mockData = VerificationPageDataUpdateMock.default.collectedData!

        // Mock number of attempted scans
        controller.analyticsClient.countDidStartDocumentScan(for: .front)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)
        controller.analyticsClient.countDidStartDocumentScan(for: .back)

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockDataResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Verify submit request
        XCTAssertEqual(mockAPIClient.verificationSessionSubmit.requestHistory.count, 1)
        mockAPIClient.verificationSessionSubmit.respondToRequests(
            with: .success(mockSubmitResponse)
        )

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify missing got updated
        XCTAssertEqual(try controller.verificationPageResponse?.get().requirements.missing, mockSubmitResponse.requirements.missing)

        // Verify collectedData got cleared
        XCTAssertEqual(controller.collectedData, StripeAPI.VerificationPageCollectedData())

        // Verify submitted is false
        XCTAssertEqual(controller.isVerificationPageSubmitted, false)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        XCTAssertEqual(
            try? mockFlowController.transitionedWithUpdateDataResult?.get(),
            mockSubmitResponse
        )
    }

    func testSaveDataSubmitsErrorResponse() throws {
        let mockError = NSError(domain: "", code: 0, userInfo: nil)

        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Mock time to submit
        mockFlowController.isFinishedCollecting = true

        let mockData = StripeAPI.VerificationPageCollectedData(biometricConsent: true)
        let mockResponse = try VerificationPageDataMock.response200.make()

        // Save data
        controller.saveAndTransition(from: .biometricConsent, collectedData: mockData) {
            self.exp.fulfill()
        }

        // Respond to save data request with success
        mockAPIClient.verificationPageData.respondToRequests(with: .success(mockResponse))

        let submitRequestExp = expectation(description: "submit request made")
        mockAPIClient.verificationSessionSubmit.callBackOnRequest {
            submitRequestExp.fulfill()
        }
        wait(for: [submitRequestExp], timeout: 1)

        // Respond with error
        mockAPIClient.verificationSessionSubmit.respondToRequests(with: .failure(mockError))

        // Verify completion block is called
        wait(for: [exp], timeout: 1)

        // Verify not submitted
        XCTAssertEqual(controller.isVerificationPageSubmitted, false)

        // Verify no succeed analytic
        XCTAssertEqual(mockAnalyticsClient.loggedAnalyticsPayloads.count, 0)

        // Verify response sent to flowController
        wait(for: [mockFlowController.didTransitionToNextScreenExp], timeout: 1)
        guard case .failure = mockFlowController.transitionedWithUpdateDataResult else {
            return XCTFail("Expected failure")
        }
    }

    func testVerifyAndTransitionWithoutDelay() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        exp = XCTestExpectation(description: "transition finished")
        controller.verifyAndTransition(simulateDelay: false) {
            self.exp.fulfill()
        }

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": false]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testVerifyAndTransitionWithDelay() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        exp = XCTestExpectation(description: "transition finished")
        controller.verifyAndTransition(simulateDelay: true) {
            self.exp.fulfill()
        }

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": true]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testUnverifyAndTransitionWithoutDelay() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        exp = XCTestExpectation(description: "transition finished")
        controller.unverifyAndTransition(simulateDelay: false) {
            self.exp.fulfill()
        }

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": false]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testUnverifyAndTransitionWithDelay() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Verify
        exp = XCTestExpectation(description: "transition finished")
        controller.unverifyAndTransition(simulateDelay: true) {
            self.exp.fulfill()
        }

        XCTAssertEqual(mockAPIClient.verifyUnverifyRequest.requestHistory.count, 1)

        XCTAssertEqual(
            mockAPIClient.verifyUnverifyRequest.requestHistory.first,
            ["simulateDelay": true]
        )

        mockAPIClient.verifyUnverifyRequest.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))

        wait(for: [exp], timeout: 1)

        XCTAssertEqual(controller.testModeReturnValue, IdentityVerificationSheet.VerificationFlowResult.flowCompleted)
    }

    func testGeneratePhoneOtp() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Verify
        controller.generatePhoneOtp { _ in
            self.exp.fulfill()
        }

        XCTAssertEqual(mockAPIClient.verificationPageGeneratePhoneOtp.requestHistory.count, 1)

        // Respond with generatePhoneOtp, trigger callback
        mockAPIClient.verificationPageGeneratePhoneOtp.respondToRequests(with: .success(try VerificationPageDataMock.response200.make()))
        wait(for: [exp], timeout: 1)
    }

    func testCannotVerifyPhoneOtp() throws {
        // Mock initial VerificationPage request successful
        controller.verificationPageResponse = .success(try VerificationPageMock.response200.make())

        // Verify
        controller.sendCannotVerifyPhoneOtpAndTransition(completion: {})

        XCTAssertEqual(mockAPIClient.verificationPageCannotVerifyPhoneOtp.requestHistory.count, 1)
    }

    func testDismissResultNotSubmitted() throws {
        controller.verificationSheetFlowControllerDidDismissNativeView(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCanceled)
    }

    func testDismissResultSubmitted() throws {
        controller.isVerificationPageSubmitted = true
        controller.verificationSheetFlowControllerDidDismissNativeView(mockFlowController)
        XCTAssertEqual(mockDelegate.result, .flowCompleted)
    }
}

private final class MockDelegate: VerificationSheetControllerDelegate {
    private(set) var result: IdentityVerificationSheet.VerificationFlowResult?

    func verificationSheetController(
        _ controller: VerificationSheetControllerProtocol,
        didFinish result: IdentityVerificationSheet.VerificationFlowResult
    ) {
        self.result = result
    }
}
