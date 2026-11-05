//
//  IdentityAPIClientNetworkedIdentityActionsTest.swift
//  StripeIdentityTests
//

@_spi(STP) import StripeCore
@_spi(STP) @testable import StripeIdentity
import XCTest

@MainActor
final class IdentityAPIClientNetworkedIdentityActionsTest: XCTestCase {
    func testReuseIsCommittedOnceTheSharedDocumentSatisfiesTheRequirement() async throws {
        let page = try makePage(direction: "consumer_to_merchant", missing: ["biometric_consent", "face"])

        let committed = try await verificationIfCommitted(.resumeReuse, page: page)

        XCTAssertEqual(committed?.id, page.id)
        XCTAssertEqual(committed?.requirements.missing, page.requirements.missing)
        XCTAssertEqual(committed?.requirements.errors, [])
    }

    func testReuseIsNotCommittedWhileTheDocumentIsStillMissing() async throws {
        let page = try makePage(direction: "consumer_to_merchant", missing: ["id_document_front", "face"])

        let committed = try await verificationIfCommitted(.resumeReuse, page: page)

        XCTAssertNil(committed)
    }

    func testSaveIsCommittedWhenTheSessionRecordsTheSaveConsent() async throws {
        let page = try makePage(direction: "merchant_to_consumer", missing: ["id_document_front", "face"])

        let committed = try await verificationIfCommitted(.resumeSave, page: page)

        XCTAssertEqual(committed?.id, page.id)
    }

    func testSaveReadBackAfterSubmissionIsClosed() async throws {
        // Given the save consent was recorded after the verification was submitted
        let page = try makePage(direction: "merchant_to_consumer", missing: [], submitted: true)

        let committed = try await verificationIfCommitted(.resumeSave, page: page)

        // Then it reads back as a finished verification, which the host accepts
        XCTAssertEqual(committed?.submittedAndClosed(), true)
    }

    func testOtherDirectionIsNotCommitted() async throws {
        let page = try makePage(direction: "merchant_to_consumer", missing: [])

        let committed = try await verificationIfCommitted(.resumeReuse, page: page)

        XCTAssertNil(committed)
    }

    private func verificationIfCommitted(
        _ route: NetworkedIdentityRoute,
        page: StripeAPI.VerificationPage
    ) async throws -> StripeAPI.VerificationPageData? {
        let api = IdentityAPIClientTestMock()
        // Reading the session back responds with `page` as soon as it's requested.
        api.verificationPage.callBackOnRequest { [weak api] in
            api?.verificationPage.respondToRequests(with: .success(page))
        }
        let actions = IdentityAPIClientNetworkedIdentityActions(apiClient: api)
        return try await actions.verificationIfCommitted(route)
    }

    private func makePage(
        direction: String,
        missing: [String],
        submitted: Bool = false
    ) throws -> StripeAPI.VerificationPage {
        var fixture = try XCTUnwrap(
            JSONSerialization.jsonObject(with: VerificationPageMock.response200.data()) as? [String: Any]
        )
        if submitted {
            fixture["submitted"] = true
            fixture["status"] = "processing"
        }
        fixture["networked_identity"] = [
            "save_enabled": true,
            "reuse_enabled": true,
            "state": ["consented": true, "skipped": false, "direction": direction],
        ]
        fixture["requirements"] = ["missing": missing]
        return try StripeJSONDecoder().decode(
            StripeAPI.VerificationPage.self,
            from: JSONSerialization.data(withJSONObject: fixture)
        )
    }
}
