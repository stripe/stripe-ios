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
            XCTAssertEqual(payload["name"] as? String, event.name.rawValue)
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
