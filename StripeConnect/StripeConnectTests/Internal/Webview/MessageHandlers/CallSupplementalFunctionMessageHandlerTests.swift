@_spi(PreviewConnect) @testable import StripeConnect
import XCTest

class CallSupplementalFunctionMessageHandlerTests: ScriptWebTestBase {
    @MainActor
    func testMessageSend() async throws {
        let expectation = self.expectation(description: "Message received")

        webView.addMessageHandler(messageHandler: CallSupplementalFunctionMessageHandler(
            analyticsClient: MockComponentAnalyticsClient(commonFields: .mock),
            didReceiveMessage: { payload in
                XCTAssertEqual(payload.functionName, .handleCheckScanSubmitted)
                XCTAssertEqual(payload.invocationId, "testInvocation")
                XCTAssertEqual(payload.args, SupplementalFunctionArgs.handleCheckScanSubmitted(.init(checkScanToken: "testToken")))
                expectation.fulfill()
            }
        ))

        try await webView.evaluateCallSupplementalFunction(functionName: .handleCheckScanSubmitted, invocationId: "testInvocation", args: "[{\"checkScanToken\":\"testToken\"}]")

        await fulfillment(of: [expectation], timeout: TestHelpers.defaultTimeout)
    }
}
