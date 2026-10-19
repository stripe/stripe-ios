import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable @_spi(STP) import StripeCore

final class STPTelemetryClientTest: APIStubbedTestCase {
    private var originalForceTelemetry = false
    private var originalFraudSignalsEnabled = false
    private var originalData: FraudDetectionData!
    private var originalStoredData: FraudDetectionData?

    override func setUp() {
        super.setUp()
        originalForceTelemetry = STPTelemetryClient._forceShouldSendTelemetryInTests
        originalFraudSignalsEnabled = StripeAPI.advancedFraudSignalsEnabled
        STPTelemetryClient._forceShouldSendTelemetryInTests = true
        StripeAPI.advancedFraudSignalsEnabled = true
        let data = FraudDetectionData.shared
        originalData = FraudDetectionData(
            sid: data.sid, muid: data.muid, guid: data.guid, sidCreationDate: data.sidCreationDate
        )
        originalStoredData = UserDefaults.standard.fraudDetectionData
        data.reset()
        addTeardownBlock { self.restoreState() }
    }

    private func restoreState() {
        STPTelemetryClient._forceShouldSendTelemetryInTests = originalForceTelemetry
        StripeAPI.advancedFraudSignalsEnabled = originalFraudSignalsEnabled
        let data = FraudDetectionData.shared
        data.sid = originalData.sid
        data.muid = originalData.muid
        data.guid = originalData.guid
        data.sidCreationDate = originalData.sidCreationDate
        UserDefaults.standard.fraudDetectionData = originalStoredData
    }

    func testAcquiresIDsWhileApplePayCheckIsBlocked() {
        // Given a capability check that cannot finish until the test releases it
        let queue = DispatchQueue(label: "test.apple-pay-capability")
        let started = expectation(description: "Capability check started")
        let release = DispatchSemaphore(value: 0)
        defer {
            release.signal()
            queue.sync {}
        }
        var checkCount = 0
        let collector = DeviceSupportsApplePayCollector(queue: queue) { _ in
            checkCount += 1
            XCTAssertFalse(Thread.isMainThread)
            started.fulfill()
            XCTAssertEqual(release.wait(timeout: .now() + 10), .success)
            return true
        }
        let client = STPTelemetryClient(sessionConfiguration: .ephemeral, deviceSupportsApplePayCollector: collector)

        // When telemetry is sent while PassKit is still pending
        sendTelemetry(client, expectedApplePayCapability: nil)
        wait(for: [started], timeout: 5)

        // Then IDs are available and persisted without waiting for PassKit
        var params: [String: Any] = [:]
        client.addTelemetryFields(toParams: &params)
        XCTAssertEqual(params["muid"] as? String, "muid_test")
        XCTAssertEqual(params["guid"] as? String, "guid_test")
        XCTAssertEqual(params["sid"] as? String, "sid_test")
        XCTAssertEqual(UserDefaults.standard.fraudDetectionData, FraudDetectionData.shared)

        // ...and another request also completes, without queuing another capability check
        sendTelemetry(client, expectedApplePayCapability: nil)
        release.signal()
        queue.sync {}
        XCTAssertEqual(checkCount, 1)
    }

    func testIncludesResolvedApplePayCapability() {
        let originalNetworks = StripeAPI.additionalEnabledApplePayNetworks
        defer { StripeAPI.additionalEnabledApplePayNetworks = originalNetworks }
        let queue = DispatchQueue(label: "test.apple-pay-capability")
        let collector = DeviceSupportsApplePayCollector(queue: queue) { networks in networks.contains(.JCB) }
        let client = STPTelemetryClient(sessionConfiguration: .ephemeral, deviceSupportsApplePayCollector: collector)
        for supported in [false, true] {
            // Given a network configuration whose capability has not been checked yet
            StripeAPI.additionalEnabledApplePayNetworks = supported ? [.JCB] : []
            sendTelemetry(client, expectedApplePayCapability: nil)

            // When the background check finishes
            queue.sync {}

            // Then later telemetry includes the result for the current networks, including false
            sendTelemetry(client, expectedApplePayCapability: supported)
        }
    }

    private func sendTelemetry(_ client: STPTelemetryClient, expectedApplePayCapability: Bool?) {
        stub(condition: isHost("m.stripe.com")) { request in
            let payload = try? JSONSerialization.jsonObject(with: request.ohhttpStubs_httpBody ?? Data()) as? [String: Any]
            let otherData = payload?["b"] as? [String: Any]
            XCTAssertNotNil(otherData)
            if let expectedApplePayCapability {
                XCTAssertEqual(otherData?["m"] as? Bool, expectedApplePayCapability)
            } else {
                XCTAssertNil(otherData?["m"])
            }
            return HTTPStubsResponse(
                jsonObject: ["muid": "muid_test", "guid": "guid_test", "sid": "sid_test"],
                statusCode: 200,
                headers: nil
            )
        }
        let completed = expectation(description: "Telemetry request completed")
        client.sendTelemetryData { result in
            if case .failure(let error) = result {
                XCTFail("Telemetry failed: \(error)")
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }
}
