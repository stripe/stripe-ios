//
//  HostControllerEventTests.swift
//  StripeFinancialConnectionsTests
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripeFinancialConnections
import XCTest

final class HostControllerEventTests: XCTestCase {
    private let mockAnalytics = MockAnalyticsClientV2()
    private let eventRecorder = EventRecorder()
    private let apiClient = FinancialConnectionsAsyncAPIClient(apiClient: APIStubbedTestCase.stubbedAPIClient())
    private lazy var analyticsClient = FinancialConnectionsAnalyticsClient(analyticsClient: mockAnalytics)
    private lazy var hostController = makeHostController()

    func testOpenAndBrowserLaunchUseManifestAnalyticsContext() throws {
        // Given a session that uses the browser flow
        let synchronize = try makeSynchronize()

        // When the initial request succeeds
        hostController.hostViewController(hostController.hostViewController, didFetch: synchronize)

        // Then each forwarded event has one emission record with the session context
        XCTAssertEqual(eventRecorder.events.map(\.name), [.open, .flowLaunchedInBrowser])
        XCTAssertEqual(emissionRecords.count, 2)
        for (event, record) in zip(eventRecorder.events, emissionRecords) {
            XCTAssertEqual(event.financialConnectionsSessionId, synchronize.manifest.id)
            XCTAssertEqual(record["las_id"] as? String, synchronize.manifest.id)
            XCTAssertEqual(record["context_source"] as? String, "native_sdk")
            XCTAssertEqual(try eventPayload(record)["name"] as? String, event.name.rawValue)
        }
    }

    func testEveryEventDelegateLogsTheForwardedEventExactlyOnce() throws {
        // Given a synchronized session and the native flow controller
        let synchronize = try makeSynchronize()
        hostController.hostViewController(hostController.hostViewController, didFetch: synchronize)
        let nativeController = makeNativeController(synchronize)

        // When events arrive from the host, native flow, browser, and server error path
        hostController.hostViewController(
            hostController.hostViewController,
            didReceiveEvent: .init(name: .cancel)
        )
        hostController.nativeFlowController(
            nativeController,
            didReceiveEvent: .init(name: .institutionSelected, metadata: .init(institutionName: "Test Bank"))
        )
        hostController.webFlowViewController(
            UIViewController(),
            didReceiveEvent: .init(name: .success, metadata: .init(manualEntry: true))
        )
        hostController.analyticsClient(
            analyticsClient,
            didReceiveEvent: .init(name: .error, metadata: .init(errorCode: .noEligibleAccounts))
        )

        // Then the callback and analytics preserve the same sequence and metadata
        XCTAssertEqual(
            eventRecorder.events.map(\.name),
            [.open, .flowLaunchedInBrowser, .cancel, .institutionSelected, .success, .error]
        )
        XCTAssertEqual(emissionRecords.count, eventRecorder.events.count)
        for (event, record) in zip(eventRecorder.events, emissionRecords) {
            let payload = try eventPayload(record)
            XCTAssertEqual(event.financialConnectionsSessionId, synchronize.manifest.id)
            XCTAssertEqual(payload["name"] as? String, event.name.rawValue)
            XCTAssertEqual(payload["financialConnectionsSessionId"] as? String, synchronize.manifest.id)
            XCTAssertEqual(payload["metadata"] as? NSDictionary, event.metadata.dictionary as NSDictionary)
        }
    }

    func testServerErrorsKeepTheirCodeWithoutRecursiveEmissions() throws {
        // Given a synchronized session and a server-provided user-facing error
        let synchronize = try makeSynchronize()
        hostController.hostViewController(hostController.hostViewController, didFetch: synchronize)
        let error = try MakeStripeAPIError(
            statusCode: 400,
            extraFields: [
                "events_to_emit": """
                [{"type":"error","error":{"error_code":"no_eligible_accounts"}}]
                """,
            ]
        )

        // When an error is logged for a visible pane
        analyticsClient.logUnexpectedError(error, errorName: "test_error", pane: .accountPicker)

        // Then the existing error diagnostic and one public emission are recorded
        XCTAssertEqual(eventRecorder.events.last?.metadata.errorCode, .noEligibleAccounts)
        XCTAssertEqual(emissionRecords.count, 3)
        XCTAssertEqual(mockAnalytics.loggedAnalyticPayloads(withEventName: "linked_accounts.error.unexpected").count, 1)
    }

    func testEventsAreSuppressedUntilTheSessionIdIsKnown() throws {
        // Given a new presentation that has not completed its initial request
        let nativeController = makeNativeController(try makeSynchronize())

        // When any of the event sources produces an event
        hostController.hostViewController(hostController.hostViewController, didReceiveEvent: .init(name: .cancel))
        hostController.nativeFlowController(nativeController, didReceiveEvent: .init(name: .accountsSelected))
        hostController.webFlowViewController(UIViewController(), didReceiveEvent: .init(name: .success))
        analyticsClient.logUnexpectedError(
            NSError(domain: "test_initialization", code: 1),
            errorName: "initialization_failed",
            pane: .unparsable
        )

        // Then no event with a missing or client-secret-derived identifier is published
        XCTAssertTrue(eventRecorder.events.isEmpty)
        XCTAssertTrue(emissionRecords.isEmpty)
        XCTAssertEqual(mockAnalytics.loggedAnalyticPayloads(withEventName: "linked_accounts.error.unexpected").count, 1)
    }

    func testInitializationFailureIsStillReturnedThroughCompletion() {
        // Given a failed initial request with no session identifier
        let error = NSError(domain: "test_initialization", code: 1)

        // When the loading screen finishes with that failure
        hostController.hostViewControllerDidFinish(hostController.hostViewController, lastError: error)

        // Then completion retains the original failure without publishing an incomplete event
        guard case .failed(let completedError) = eventRecorder.result else {
            return XCTFail("Expected initialization failure")
        }
        XCTAssertEqual(completedError as NSError, error)
        XCTAssertTrue(eventRecorder.events.isEmpty)
        XCTAssertTrue(emissionRecords.isEmpty)
    }

    func testANewPresentationDoesNotReuseThePreviousSessionId() throws {
        // Given a completed initialization for one presentation
        let first = try makeSynchronize(id: "fcsess_first")
        hostController.hostViewController(hostController.hostViewController, didFetch: first)
        let secondHost = makeHostController()

        // When another presentation emits before and after its own initialization
        secondHost.hostViewController(secondHost.hostViewController, didReceiveEvent: .init(name: .cancel))
        XCTAssertEqual(eventRecorder.events.count, 2)
        let second = try makeSynchronize(id: "fcsess_second")
        secondHost.hostViewController(secondHost.hostViewController, didFetch: second)

        // Then each presentation uses only its own canonical session identifier
        XCTAssertEqual(
            eventRecorder.events.map(\.financialConnectionsSessionId),
            ["fcsess_first", "fcsess_first", "fcsess_second", "fcsess_second"]
        )
    }

    func testLinkedAccountResultDoesNotReplaceTheEventSessionId() throws {
        // Given a flow initialized with the canonical session identifier
        let synchronize = try makeSynchronize()
        hostController.hostViewController(hostController.hostViewController, didFetch: synchronize)
        let nativeController = makeNativeController(synchronize)

        // When completion returns a linked-account identifier
        hostController.nativeFlowController(nativeController, didFinish: .completed(.linkedAccount(id: "fca_linked_account")))
        hostController.nativeFlowController(nativeController, didReceiveEvent: .init(name: .success))

        // Then the event still references the session that was synchronized
        XCTAssertEqual(eventRecorder.events.last?.financialConnectionsSessionId, synchronize.manifest.id)
    }

    func testEmptySessionIdFailsInitializationWithoutPublishingEvents() throws {
        // Given an invalid manifest without a session identifier
        let synchronize = try makeSynchronize(id: "")

        // When the manifest is received
        hostController.hostViewController(hostController.hostViewController, didFetch: synchronize)

        // Then initialization fails without creating a flow or publishing incomplete events
        guard case .failed(let error) = eventRecorder.result else {
            return XCTFail("Expected initialization failure")
        }
        XCTAssert(error is FinancialConnectionsSheetError)
        XCTAssertTrue(hostController.navigationController.topViewController === hostController.hostViewController)
        XCTAssertTrue(eventRecorder.events.isEmpty)
        XCTAssertTrue(emissionRecords.isEmpty)
    }

    private var emissionRecords: [[String: Any]] {
        mockAnalytics.loggedAnalyticPayloads(withEventName: "linked_accounts.external_on_event.emitted")
    }

    private func eventPayload(_ record: [String: Any]) throws -> [String: Any] {
        let serialized = try XCTUnwrap(record["event_payload"] as? String)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(serialized.utf8)) as? [String: Any])
    }

    private func makeHostController() -> HostController {
        let controller = HostController(
            apiClient: apiClient,
            analyticsClientV1: MockAnalyticsClient(),
            clientSecret: "fcsess_test_secret_not_a_session_id",
            returnURL: nil,
            configuration: .init(),
            elementsSessionContext: nil,
            publishableKey: nil,
            stripeAccount: nil,
            analyticsClient: analyticsClient
        )
        controller.delegate = eventRecorder
        return controller
    }

    private func makeSynchronize(id: String = "fcsess_canonical") throws -> FinancialConnectionsSynchronize {
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: FinancialConnectionsSynchronizeMock.synchronize.data()) as? [String: Any]
        )
        var manifest = try XCTUnwrap(payload["manifest"] as? [String: Any])
        manifest["id"] = id
        manifest["features"] = ["bank_connections_mobile_native_version_killswitch": true]
        payload["manifest"] = manifest
        return try StripeJSONDecoder().decode(
            FinancialConnectionsSynchronize.self,
            from: JSONSerialization.data(withJSONObject: payload)
        )
    }

    private func makeNativeController(_ synchronize: FinancialConnectionsSynchronize) -> NativeFlowController {
        let dataManager = NativeFlowAPIDataManager(
            manifest: synchronize.manifest,
            configuration: .init(),
            visualUpdate: synchronize.visual,
            returnURL: nil,
            consentPaneModel: synchronize.text?.consentPane,
            accountPickerPane: synchronize.text?.accountPickerPane,
            apiClient: apiClient,
            clientSecret: "fcsess_test_secret_not_a_session_id",
            analyticsClient: analyticsClient,
            elementsSessionContext: nil
        )
        return NativeFlowController(dataManager: dataManager, navigationController: hostController.navigationController)
    }
}

private final class EventRecorder: HostControllerDelegate {
    var events: [FinancialConnectionsEvent] = []
    var result: HostControllerResult?

    func hostController(_ hostController: HostController, didReceiveEvent event: FinancialConnectionsEvent) {
        events.append(event)
    }

    func hostController(
        _ hostController: HostController,
        viewController: UIViewController,
        didFinish result: HostControllerResult,
        linkAccountSessionId: String?
    ) {
        self.result = result
    }
}
