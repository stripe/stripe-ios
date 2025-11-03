import SafariServices
@_spi(DashboardOnly) @testable import StripeConnect
@_spi(STP) import StripeCore
import WebKit
import XCTest

class CheckScanningControllerTests: XCTestCase {
    let componentManager = EmbeddedComponentManager(fetchClientSecret: {
        return nil
    })

    override func setUp() {
        super.setUp()

        STPAPIClient.shared.publishableKey = "pk_test"
        componentManager.shouldLoadContent = false
        componentManager.analyticsClientFactory = MockComponentAnalyticsClient.init
    }

    class CheckScanningControllerDelegatePassThrough: CheckScanningControllerDelegate {
        var checkScanningDidFail: ((_ checkScanning: CheckScanningController, _ error: any Error) -> Void)?

        init(checkScanningDidFail: ((CheckScanningController, any Error) -> Void)? = nil) {
            self.checkScanningDidFail = checkScanningDidFail
        }

        func checkScanning(_ checkScanning: CheckScanningController, didFailLoadWithError error: any Error) {
            checkScanningDidFail?(checkScanning, error)
        }
    }

    @MainActor
    func testDelegate() async throws {
        let delegate = CheckScanningControllerDelegatePassThrough()
        let controller = componentManager.createCheckScanningController { _ in }
        controller.delegate = delegate

        let expectationDidFail = XCTestExpectation(description: "didFail called")
        delegate.checkScanningDidFail = { failedController, error in
            XCTAssert(controller === failedController)
            XCTAssertEqual((error as? EmbeddedComponentError)?.type, .rateLimitError)
            XCTAssertEqual((error as? EmbeddedComponentError)?.description, "Error message")
            expectationDidFail.fulfill()
        }
        try await controller.webVC.webView.evaluateOnLoadError(type: "rate_limit_error", message: "Error message")

        await fulfillment(of: [expectationDidFail], timeout: TestHelpers.defaultTimeout)
    }

    @MainActor
    func testFetchInitComponentProps() async throws {
        let controller = componentManager.createCheckScanningController { _ in }

        try await controller.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                                    json: "{}",
                                                                    expectedResponse: """
            {"setHandleCheckScanSubmitted":true}
            """)
    }
}
