//
//  SeededDocumentsNetworkedIdentityAPIClientTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
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
    func testAttachingASeededToken_succeedsWithoutCallingAPI() async throws {
        let delegate = NetworkedIdentityActionsTestMock()
        let sut = SeededDocumentsNetworkedIdentityActions(delegate: delegate)

        let data = try await sut.attachDocument(
            associationToken: SeededDocumentsNetworkedIdentityAPIClient.seededTokenPrefix + "seeded_iddoc_passport"
        )

        XCTAssertEqual(data.id, "vs_target")
        XCTAssertTrue(delegate.attachDocument.requestHistory.isEmpty)
    }

    @MainActor
    func testAttachingARealToken_callsAPI() async throws {
        let delegate = NetworkedIdentityActionsTestMock()
        let sut = SeededDocumentsNetworkedIdentityActions(delegate: delegate)

        let attach = Task { try await sut.attachDocument(associationToken: "token_1") }
        while delegate.attachDocument.pendingRequestCount == 0 {
            await Task.yield()
        }
        delegate.attachDocument.respondToNext(with: .success(niActionPageData()))

        let data = try await attach.value
        XCTAssertEqual(delegate.attachDocument.requestHistory, ["token_1"])
        XCTAssertEqual(data, niActionPageData())
    }
}
