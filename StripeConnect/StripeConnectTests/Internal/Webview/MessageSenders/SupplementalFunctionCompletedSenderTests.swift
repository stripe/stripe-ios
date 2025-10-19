@testable import StripeConnect
import XCTest

class SupplementalFunctionCompletedSenderTests: ScriptWebTestBase {
    func testSendMessage_successResult() throws {
        try validateMessageSent(sender: SupplementalFunctionCompletedSender(
            payload: .init(functionName: .handleCheckScanSubmitted, invocationId: "testInvocationId", result: .success(.handleCheckScanSubmitted(.init())))
        ))
    }

    func testSendMessage_errorResult() throws {
        try validateMessageSent(sender: SupplementalFunctionCompletedSender(
            payload: .init(functionName: .handleCheckScanSubmitted, invocationId: "testInvocationId", result: .error("error message"))
        ))
    }

    func testSenderSignature_successResult() {
        XCTAssertEqual(
            try SupplementalFunctionCompletedSender(
                payload: .init(functionName: .handleCheckScanSubmitted, invocationId: "testInvocationId", result: .success(.handleCheckScanSubmitted(.init())))
            ).javascriptMessage(),
            """
            window.supplementalFunctionCompleted({"functionName":"handleCheckScanSubmitted","invocationId":"testInvocationId","result":"success","returnValue":{}});
            """
        )
    }

    func testSenderSignature_errorResult() {
        XCTAssertEqual(
            try SupplementalFunctionCompletedSender(
                payload: .init(functionName: .handleCheckScanSubmitted, invocationId: "testInvocationId", result: .error("error message"))
            ).javascriptMessage(),
            """
            window.supplementalFunctionCompleted({"error":"error message","functionName":"handleCheckScanSubmitted","invocationId":"testInvocationId","result":"error"});
            """
        )
    }
}
