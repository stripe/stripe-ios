//
//  HostControllerFCLiteAdapterTests.swift
//  StripeFinancialConnectionsTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) @_spi(v25) import StripeFinancialConnections
import XCTest

/// Verifies that `HostController` correctly adapts FC Lite's `FinancialConnectionsSDKResult`
/// into the `HostControllerResult` expected by the rest of the SDK.
class HostControllerFCLiteAdapterTests: XCTestCase {

    // MARK: - Test doubles

    private class StubbedSessionAPIClient: EmptyFinancialConnectionsAPIClient {
        var sessionResult: Result<StripeAPI.FinancialConnectionsSession, Error>?

        override func fetchFinancialConnectionsSession(
            clientSecret: String
        ) -> Promise<StripeAPI.FinancialConnectionsSession> {
            let promise = Promise<StripeAPI.FinancialConnectionsSession>()
            switch sessionResult {
            case .success(let session):
                promise.resolve(with: session)
            case .failure(let error):
                promise.reject(with: error)
            case .none:
                break  // leave unresolved to assert no re-fetch happened
            }
            return promise
        }
    }

    private class MockHostControllerDelegate: HostControllerDelegate {
        private(set) var didFinishResult: HostControllerResult?
        private(set) var receivedEvents: [FinancialConnectionsEvent] = []
        var onFinish: (() -> Void)?

        func hostController(
            _ hostController: HostController,
            viewController: UIViewController,
            didFinish result: HostControllerResult,
            linkAccountSessionId: String?
        ) {
            didFinishResult = result
            onFinish?()
        }

        func hostController(
            _ hostController: HostController,
            didReceiveEvent event: FinancialConnectionsEvent
        ) {
            receivedEvents.append(event)
        }
    }

    // MARK: - Fixtures

    private func makeHostController(
        apiClient: FinancialConnectionsAPI
    ) -> (HostController, MockHostControllerDelegate) {
        let host = HostController(
            apiClient: apiClient,
            analyticsClientV1: MockAnalyticsClient(),
            clientSecret: "las_123",
            returnURL: nil,
            configuration: .init(),
            elementsSessionContext: nil,
            publishableKey: "pk_test",
            stripeAccount: nil
        )
        let delegate = MockHostControllerDelegate()
        host.delegate = delegate
        return (host, delegate)
    }

    private func makeSession(
        id: String = "fcsess_123",
        status: StripeAPI.FinancialConnectionsSession.Status? = nil,
        statusDetails: StripeAPI.FinancialConnectionsSession.StatusDetails? = nil
    ) -> StripeAPI.FinancialConnectionsSession {
        StripeAPI.FinancialConnectionsSession(
            clientSecret: "las_123",
            id: id,
            accounts: .init(data: [], hasMore: false),
            livemode: false,
            paymentAccount: nil,
            bankAccountToken: nil,
            status: status,
            statusDetails: statusDetails
        )
    }

    private func makeLinkedBank() -> FinancialConnectionsLinkedBank {
        FinancialConnectionsLinkedBank(
            sessionId: "fcsess_from_lite",
            accountId: "acct_1",
            displayName: nil,
            bankName: "Test Bank",
            last4: "4242",
            instantlyVerified: true
        )
    }

    private func makeManifest(isInstantDebits: Bool) -> FinancialConnectionsSessionManifest {
        FinancialConnectionsSessionManifest(
            accountholderCustomerEmailAddress: nil,
            accountholderIsLinkConsumer: nil,
            accountholderPhoneNumber: nil,
            accountholderToken: nil,
            accountDisconnectionMethod: nil,
            activeAuthSession: nil,
            activeInstitution: nil,
            allowManualEntry: false,
            appVerificationEnabled: nil,
            assignmentEventId: nil,
            linkBrand: nil,
            businessName: nil,
            cancelUrl: nil,
            consentAcquiredAt: nil,
            consentRequired: false,
            customManualEntryHandling: false,
            disableLinkMoreAccounts: false,
            displayText: nil,
            experimentAssignments: nil,
            features: nil,
            hostedAuthUrl: nil,
            id: "las_123",
            initialInstitution: nil,
            instantVerificationDisabled: false,
            institutionSearchDisabled: false,
            isEndUserFacing: nil,
            isLinkWithStripe: nil,
            isNetworkingUserFlow: nil,
            isStripeDirect: nil,
            livemode: false,
            manualEntryMode: .automatic,
            manualEntryUsesMicrodeposits: false,
            nextPane: .consent,
            paymentMethodType: nil,
            permissions: [],
            product: isInstantDebits ? "instant_debits" : "connections",
            singleAccount: true,
            skipSuccessPane: nil,
            successUrl: nil,
            theme: nil
        )
    }

    // MARK: - Completed

    func testFinancialConnectionsCompletedReFetchesFullSession() {
        // Given a stubbed client that returns a full session on re-fetch
        let apiClient = StubbedSessionAPIClient()
        apiClient.sessionResult = .success(makeSession(id: "fcsess_refetched"))
        let (host, delegate) = makeHostController(apiClient: apiClient)

        // When FC Lite reports a completed Financial Connections result
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(
            .completed(.financialConnections(makeLinkedBank())),
            manifest: makeManifest(isInstantDebits: false)
        )
        wait(for: [finished], timeout: 5.0)

        // Then the host result carries the re-fetched full session and a success event is emitted
        guard case .completed(.financialConnections(let session)) = delegate.didFinishResult else {
            return XCTFail("Expected .completed(.financialConnections), got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertEqual(session.id, "fcsess_refetched")
        XCTAssertEqual(delegate.receivedEvents.map(\.name), [.success])
    }

    func testFinancialConnectionsCompletedReFetchFailureMapsToFailed() {
        // Given a stubbed client whose re-fetch fails
        let apiClient = StubbedSessionAPIClient()
        apiClient.sessionResult = .failure(FinancialConnectionsSheetError.unknown(debugDescription: "boom"))
        let (host, delegate) = makeHostController(apiClient: apiClient)

        // When FC Lite reports a completed Financial Connections result
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(
            .completed(.financialConnections(makeLinkedBank())),
            manifest: makeManifest(isInstantDebits: false)
        )
        wait(for: [finished], timeout: 5.0)

        // Then the failure is surfaced
        guard case .failed = delegate.didFinishResult else {
            return XCTFail("Expected .failed, got \(String(describing: delegate.didFinishResult))")
        }
    }

    func testLinkedAccountCompletedPassesThrough() {
        // Given
        let (host, delegate) = makeHostController(apiClient: StubbedSessionAPIClient())

        // When FC Lite reports a linked account
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(
            .completed(.linkedAccount(id: "la_1")),
            manifest: makeManifest(isInstantDebits: false)
        )
        wait(for: [finished], timeout: 5.0)

        // Then it passes through unchanged with a success event
        guard case .completed(.linkedAccount(let id)) = delegate.didFinishResult else {
            return XCTFail("Expected .completed(.linkedAccount), got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertEqual(id, "la_1")
        XCTAssertEqual(delegate.receivedEvents.map(\.name), [.success])
    }

    func testFailedPassesThrough() {
        // Given
        let (host, delegate) = makeHostController(apiClient: StubbedSessionAPIClient())

        // When FC Lite reports a failure
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(
            .failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "boom")),
            manifest: makeManifest(isInstantDebits: false)
        )
        wait(for: [finished], timeout: 5.0)

        // Then the failure passes through and at least one error event is emitted
        guard case .failed = delegate.didFinishResult else {
            return XCTFail("Expected .failed, got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertTrue(delegate.receivedEvents.contains { $0.name == .error })
    }

    // MARK: - Cancelled

    func testCancelledMapsToCanceled() {
        // Given a session that was cancelled for a non-custom-manual-entry reason
        let apiClient = StubbedSessionAPIClient()
        apiClient.sessionResult = .success(makeSession(status: .cancelled, statusDetails: nil))
        let (host, delegate) = makeHostController(apiClient: apiClient)

        // When FC Lite reports a cancellation for a Financial Connections flow
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(.cancelled, manifest: makeManifest(isInstantDebits: false))
        wait(for: [finished], timeout: 5.0)

        // Then it maps to canceled with a cancel event
        guard case .canceled = delegate.didFinishResult else {
            return XCTFail("Expected .canceled, got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertEqual(delegate.receivedEvents.map(\.name), [.cancel])
    }

    func testCancelledWithCustomManualEntryMapsToFailed() {
        // Given a session cancelled with reason customManualEntry
        let apiClient = StubbedSessionAPIClient()
        apiClient.sessionResult = .success(
            makeSession(
                status: .cancelled,
                statusDetails: .init(cancelled: .init(reason: .customManualEntry))
            )
        )
        let (host, delegate) = makeHostController(apiClient: apiClient)

        // When FC Lite reports a cancellation for a Financial Connections flow
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(.cancelled, manifest: makeManifest(isInstantDebits: false))
        wait(for: [finished], timeout: 5.0)

        // Then the custom-manual-entry sentinel error is surfaced and no cancel event is emitted
        guard case .failed(let error) = delegate.didFinishResult else {
            return XCTFail("Expected .failed, got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertTrue(error is FinancialConnectionsCustomManualEntryRequiredError)
        XCTAssertFalse(delegate.receivedEvents.contains { $0.name == .cancel })
    }

    func testInstantDebitsCancelledMapsToCanceledWithoutReFetch() {
        // Given an Instant Debits flow and a client whose session re-fetch never resolves
        let apiClient = StubbedSessionAPIClient()
        apiClient.sessionResult = nil  // if a re-fetch happened, the delegate would never be called
        let (host, delegate) = makeHostController(apiClient: apiClient)

        // When FC Lite reports a cancellation
        let finished = expectation(description: "finished")
        delegate.onFinish = { finished.fulfill() }
        host.handleFCLiteResult(.cancelled, manifest: makeManifest(isInstantDebits: true))
        wait(for: [finished], timeout: 5.0)

        // Then it maps to canceled immediately (no re-fetch) with a cancel event
        guard case .canceled = delegate.didFinishResult else {
            return XCTFail("Expected .canceled, got \(String(describing: delegate.didFinishResult))")
        }
        XCTAssertEqual(delegate.receivedEvents.map(\.name), [.cancel])
    }
}
