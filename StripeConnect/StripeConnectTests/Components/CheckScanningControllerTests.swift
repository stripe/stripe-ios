import SafariServices
@_spi(PrivatePreviewConnect) @testable import StripeConnect
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

        func checkScanning(_ checkScanning: CheckScanningController, didSubmitCheckScan: CheckScanningController.CheckScanDetails) async throws {
            // do nothing
        }
    }

    @MainActor
    func testDelegate() async throws {
        let delegate = CheckScanningControllerDelegatePassThrough()
        let controller = componentManager.createCheckScanningController()
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
        let controller = componentManager.createCheckScanningController()

        try await controller.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                                    json: "{}",
                                                                    expectedResponse: """
            {"setHandleCheckScanSubmitted":true}
            """)
    }

    class CheckScanningControllerDelegateWithCallback: CheckScanningControllerDelegate {
        var received: CheckScanningController.CheckScanDetails?
        private let expectation: XCTestExpectation

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func checkScanning(_ checkScanning: CheckScanningController, didSubmitCheckScan: CheckScanningController.CheckScanDetails) async throws {
            received = didSubmitCheckScan
            expectation.fulfill()
        }
    }

    @MainActor
    func testCallbackInvoked() async throws {
        let controller = componentManager.createCheckScanningController()

        let expectationCallback = XCTestExpectation(description: "handleCheckScanSubmitted called")
        let delegate = CheckScanningControllerDelegateWithCallback(expectation: expectationCallback)

        controller.delegate = delegate

        try await controller.webVC.webView.evaluateMessageWithReply(name: "fetchInitComponentProps",
                                                                    json: "{}",
                                                                    expectedResponse: """
            {"setHandleCheckScanSubmitted":true}
            """)

        try await controller.webVC.webView.evaluateMessage(
            name: "callSupplementalFunction",
            json: """
                {"functionName": "handleCheckScanSubmitted","invocationId":"0","args":[{"checkScanToken": "uspchk_123"}]}
            """
        )

        await fulfillment(of: [expectationCallback], timeout: TestHelpers.defaultTimeout)
        XCTAssertEqual(delegate.received, .init(checkScanToken: "uspchk_123"))
    }
}
