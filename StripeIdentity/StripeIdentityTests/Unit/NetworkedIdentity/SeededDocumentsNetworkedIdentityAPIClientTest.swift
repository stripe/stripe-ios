//
//  SeededDocumentsNetworkedIdentityAPIClientTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable import StripeIdentity
import XCTest

final class SeededDocumentsNetworkedIdentityAPIClientTest: XCTestCase {
    private let now = 1_700_000_000

    func testListIdentityDocuments_returnsLiveCapturedUnexpiredDocuments_withoutCallingAPI() throws {
        // Given a seeded client over a mock API
        let delegate = NetworkedIdentityAPIClientTestMock()
        let sut = SeededDocumentsNetworkedIdentityAPIClient(delegate: delegate, currentTime: { self.now })

        // When listing documents
        let documents = try awaitValue(
            sut.listIdentityDocuments(consumerSessionClientSecret: "secret", consumerPublishableKey: "pk_consumer")
        ).data

        // Then seeded documents come back and the API is never called
        XCTAssertEqual(documents.map(\.documentType), [.passport, .drivingLicense])
        XCTAssertTrue(documents.allSatisfy { $0.liveCaptured == true })
        XCTAssertTrue(documents.allSatisfy { ($0.expirationDate ?? 0) > now })
        XCTAssertTrue(documents.allSatisfy { $0.id.hasPrefix(SeededDocumentsNetworkedIdentityAPIClient.seededIDPrefix) })
        XCTAssertTrue(delegate.documentList.requestHistory.isEmpty)
    }

    func testCreateAssociationToken_forSeededDocument_returnsToken_withoutCallingAPI() throws {
        // Given a seeded client over a mock API
        let delegate = NetworkedIdentityAPIClientTestMock()
        let sut = SeededDocumentsNetworkedIdentityAPIClient(delegate: delegate, currentTime: { self.now })

        // When creating a token for a seeded document
        let token = try awaitValue(
            sut.createAssociationToken(
                identityDocumentID: SeededDocumentsNetworkedIdentityAPIClient.seededIDPrefix + "passport",
                consumerSessionClientSecret: "secret",
                consumerPublishableKey: "pk_consumer"
            )
        )

        // Then a seeded token comes back and the API is never called
        XCTAssertTrue(token.associationToken.hasPrefix("seeded_token_"))
        XCTAssertTrue(delegate.associationToken.requestHistory.isEmpty)
    }

    func testCreateAssociationToken_forRealDocument_callsAPI() {
        // Given a seeded client over a mock API
        let delegate = NetworkedIdentityAPIClientTestMock()
        let sut = SeededDocumentsNetworkedIdentityAPIClient(delegate: delegate, currentTime: { self.now })

        // When creating a token for a non-seeded document
        _ = sut.createAssociationToken(
            identityDocumentID: "iddoc_real",
            consumerSessionClientSecret: "secret",
            consumerPublishableKey: "pk_consumer"
        )

        // Then the request goes to the API
        XCTAssertEqual(delegate.associationToken.requestHistory.map(\.identityDocumentID), ["iddoc_real"])
    }

    private func awaitValue<Value>(_ future: Future<Value>) throws -> Value {
        let expectation = expectation(description: "Future resolves")
        var result: Result<Value, Error>?
        future.observe { observed in
            result = observed
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        return try XCTUnwrap(result).get()
    }

    @MainActor
    func testSeededDocumentCompletesAfterConsentWithoutRecapture() async throws {
        let (api, backend, page) = try await makeIdentityClient()
        let flow = VerificationSheetFlowControllerMock()
        let controller = VerificationSheetController(
            apiClient: api, flowController: flow, mlModelLoader: IdentityMLModelLoaderMock(),
            analyticsClient: .init(verificationSessionId: page.id, analyticsClient: MockAnalyticsClientV2())
        )
        controller.verificationPageResponse = .success(page)
        let actions = IdentityAPIClientNetworkedIdentityActions(apiClient: api)
        let attached = try await actions.attachDocument(associationToken: "seeded_token_seeded_iddoc_passport")
        let completed = expectation(description: "Consent and submission complete")

        controller.saveConsentAfterNetworkedIdentity(attached: attached) { completed.fulfill() }
        backend.verificationPageData.respondToRequests(with: .success(.init(
            id: page.id, requirements: .init(errors: [], missing: [.idDocumentFront, .idDocumentBack]),
            status: .requiresInput, submitted: false, closed: false
        )))
        await fulfillment(of: [completed], timeout: 2)

        let result = try XCTUnwrap(flow.transitionedWithUpdateDataResult).get()
        XCTAssertTrue(result.submittedAndClosed())
        XCTAssertTrue(result.requirements.missing.isEmpty)
        XCTAssertTrue(controller.isVerificationPageSubmitted)
        XCTAssertTrue(backend.verificationSessionSubmit.requestHistory.isEmpty)
    }

    @MainActor
    func testAttachingASeededToken_succeedsWithoutCallingAPI() async throws {
        let (sut, delegate, page) = try await makeIdentityClient(missing: [.biometricConsent, .idDocumentFront, .idDocumentBack, .face])

        let data = try await asyncValue(sut.attachNetworkedIdentityDocument(
            associationToken: SeededDocumentsNetworkedIdentityAPIClient.seededTokenPrefix + "seeded_iddoc_passport"
        ))

        XCTAssertEqual(data.id, page.id)
        XCTAssertEqual(data.requirements.missing, [.biometricConsent, .face])
        XCTAssertTrue(delegate.attachNetworkedIdentityDocument.requestHistory.isEmpty)
    }

    @MainActor
    func testAttachingARealToken_callsAPI() async throws {
        let delegate = IdentityAPIClientTestMock()
        let sut = SeededDocumentsIdentityAPIClient(delegate: delegate)

        let attach = sut.attachNetworkedIdentityDocument(associationToken: "token_1")
        delegate.attachNetworkedIdentityDocument.respondToNext(with: .success(niActionPageData()))

        let data = try await asyncValue(attach)
        XCTAssertEqual(delegate.attachNetworkedIdentityDocument.requestHistory, ["token_1"])
        XCTAssertEqual(data, niActionPageData())
    }

    @MainActor
    func testSeededReusePreservesSelfieAndSkipRestoresDocumentCapture() async throws {
        let (api, backend, page) = try await makeIdentityClient(missing: [.biometricConsent, .idDocumentFront, .idDocumentBack, .face])
        _ = try await asyncValue(api.attachNetworkedIdentityDocument(associationToken: "seeded_token_seeded_iddoc_passport"))
        let consent = api.updateIdentityVerificationPageData(updating: .init(clearData: nil, collectedData: .init(biometricConsent: true)))
        let response = StripeAPI.VerificationPageData(
            id: page.id, requirements: .init(errors: [], missing: [.idDocumentFront, .idDocumentBack, .face]),
            status: .requiresInput, submitted: false, closed: false
        )
        backend.verificationPageData.respondToRequests(with: .success(response))

        let updated = try await asyncValue(consent)
        XCTAssertEqual(updated.requirements.missing, [.face])
        let prematureSubmission = try await asyncValue(api.submitIdentityVerificationPage())
        XCTAssertFalse(prematureSubmission.submittedAndClosed())
        XCTAssertEqual(prematureSubmission.requirements.missing, [.face])

        let skipped = try await asyncValue(api.skipNetworkedIdentity())
        XCTAssertEqual(skipped, response)
        XCTAssertTrue(backend.networkedIdentitySkip.requestHistory.isEmpty)
    }

    @MainActor
    func testSeededReusePreservesBackendErrors() async throws {
        let (api, backend, _) = try await makeIdentityClient()
        _ = try await asyncValue(api.attachNetworkedIdentityDocument(associationToken: "seeded_token_seeded_iddoc_passport"))
        let update = api.updateIdentityVerificationPageData(updating: .init(clearData: nil, collectedData: .init(biometricConsent: true)))
        let response = try VerificationPageDataMock.response200.make()
        backend.verificationPageData.respondToRequests(with: .success(response))

        let updated = try await asyncValue(update)
        XCTAssertFalse(updated.requirements.errors.isEmpty)
        XCTAssertEqual(updated.requirements.errors, response.requirements.errors)
        let submitted = try await asyncValue(api.submitIdentityVerificationPage())
        XCTAssertFalse(submitted.submittedAndClosed())
        XCTAssertTrue(backend.verificationSessionSubmit.requestHistory.isEmpty)
    }

    @MainActor
    func testSampleSaveSucceedsWithoutCallingTheSaveEndpoints() async throws {
        let consumerAPI = SeededDocumentsNetworkedIdentityAPIClient(delegate: NetworkedIdentityAPIClientTestMock())
        let (api, backend, page) = try await makeIdentityClient(missing: [], livemode: true)

        let token = try await asyncValue(consumerAPI.createSaveAssociationToken(
            verificationSessionID: page.id, consumerSessionClientSecret: "secret", consumerPublishableKey: "pk_consumer"
        ))
        let prepared = try await asyncValue(api.prepareNetworkedIdentityDocumentSave(associationToken: token.associationToken))

        XCTAssertEqual(prepared.id, page.id)
        XCTAssertTrue(backend.prepareNetworkedIdentityDocumentSave.requestHistory.isEmpty)
    }

    @MainActor
    func testSampleAttachmentIsRejectedForLiveSessions() async throws {
        let (api, backend, _) = try await makeIdentityClient(livemode: true)
        do {
            _ = try await asyncValue(api.attachNetworkedIdentityDocument(associationToken: "seeded_token_seeded_iddoc_passport"))
            XCTFail("Sample documents must not simulate a live verification")
        } catch {
            XCTAssertTrue(backend.attachNetworkedIdentityDocument.requestHistory.isEmpty)
        }
    }

    @MainActor
    private func makeIdentityClient(
        missing: Set<StripeAPI.VerificationPageFieldType> = [.biometricConsent, .idDocumentFront, .idDocumentBack],
        livemode: Bool = false
    ) async throws -> (SeededDocumentsIdentityAPIClient, IdentityAPIClientTestMock, StripeAPI.VerificationPage) {
        let fixture: VerificationPageMock = livemode ? .response200 : .response200TestMode
        let page = try fixture.make().copyWithNewMissings(newMissings: missing)
        let backend = IdentityAPIClientTestMock(verificationSessionId: page.id)
        let api = SeededDocumentsIdentityAPIClient(delegate: backend)
        let load = api.getIdentityVerificationPage()
        backend.verificationPage.respondToRequests(with: .success(page))
        _ = try await asyncValue(load)
        return (api, backend, page)
    }

    private func asyncValue<Value>(_ future: Future<Value>) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            future.observe { continuation.resume(with: $0) }
        }
    }
}
