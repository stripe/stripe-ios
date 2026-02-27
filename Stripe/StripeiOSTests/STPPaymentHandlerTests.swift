//
//  STPPaymentHandlerTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import Stripe3DS2
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentHandlerStubbedTests: STPNetworkStubbingTestCase {
    func testPollingBehaviorWithFinalCall() {
        let mockAPIClient = STPAPIClientPollingMock()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let pollingBudget = PollingBudget(startDate: Date(), duration: 1.0)
        let expectation = self.expectation(description: "Polling completes")

        var callTimes: [Date] = []
        let startTime = Date()

        let paymentIntent = STPFixtures.paymentIntent(
            paymentMethodTypes: ["card"],
            status: .processing,
            paymentMethod: ["id": "pm_test", "type": "card", "created": Date().timeIntervalSince1970]
        )

        mockAPIClient.retrievePaymentIntentHandler = { _, _, completion in
            callTimes.append(Date())
            let status: STPPaymentIntentStatus = callTimes.count >= 2 ? .succeeded : .processing

            let responseDict = paymentIntent.allResponseFields.merging([
                "status": STPPaymentIntentStatus.string(from: status)
            ]) { _, new in new }

            let updatedPI = STPPaymentIntent.decodedObject(fromAPIResponse: responseDict)

            // Simulate 15-second network request time for first request
            DispatchQueue.main.asyncAfter(deadline: .now() + (callTimes.count == 1 ? 1.1 : 0.0)) {
                completion(updatedPI, nil)

                if callTimes.count >= 2 {
                    expectation.fulfill()
                }
            }
        }

        let currentAction = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: self,
            threeDSCustomizationSettings: STPThreeDSCustomizationSettings(),
            paymentIntent: paymentIntent,
            returnURL: nil
        ) { _, _, _ in }

        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction, pollingBudget: pollingBudget)

        wait(for: [expectation], timeout: 30.0)

        XCTAssertEqual(callTimes.count, 2, "Expected exactly 2 network calls: initial + final")

        let firstCallDelay = callTimes[0].timeIntervalSince(startTime)
        let finalCallDelay = callTimes[1].timeIntervalSince(startTime)

        XCTAssertLessThan(firstCallDelay, 1.0, "First call should happen immediately")
        XCTAssertGreaterThan(finalCallDelay, 1.1, "Final call should happen after polling budget expires")
        XCTAssertLessThan(finalCallDelay, 1.3, "Final call should happen after polling budget expires but within a reasonable time")
    }

    func testPollingBehaviorWithTimeoutThenSuccess() {
        let mockAPIClient = STPAPIClientPollingMock()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let pollingBudget = PollingBudget(startDate: Date(), duration: 1)
        let expectation = self.expectation(description: "Polling completes after timeout retry")

        var callTimes: [Date] = []
        let startTime = Date()

        let paymentIntent = STPFixtures.paymentIntent(
            paymentMethodTypes: ["card"],
            status: .processing,
            paymentMethod: ["id": "pm_test", "type": "card"]
        )

        mockAPIClient.retrievePaymentIntentHandler = { _, _, completion in
            callTimes.append(Date())

            if callTimes.count == 1 {
                // First call simulate timeout error
                let timeoutError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorTimedOut,
                    userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
                )
                completion(nil, timeoutError)
            } else {
                // Second call return success
                let responseDict = paymentIntent.allResponseFields.merging([
                    "status": STPPaymentIntentStatus.string(from: .succeeded)
                ]) { _, new in new }

                let succeededPI = STPPaymentIntent.decodedObject(fromAPIResponse: responseDict)
                completion(succeededPI, nil)
                expectation.fulfill()
            }
        }

        let currentAction = STPPaymentHandlerPaymentIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: self,
            threeDSCustomizationSettings: STPThreeDSCustomizationSettings(),
            paymentIntent: paymentIntent,
            returnURL: nil
        ) { _, _, _ in }

        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction, pollingBudget: pollingBudget)

        wait(for: [expectation], timeout: 15.0)

        XCTAssertEqual(callTimes.count, 2, "Expected exactly 2 network calls: initial timeout + retry success")

        let firstCallDelay = callTimes[0].timeIntervalSince(startTime)
        let retryCallDelay = callTimes[1].timeIntervalSince(startTime)

        XCTAssertLessThan(firstCallDelay, 0.1, "First call should happen immediately")
        XCTAssertGreaterThan(retryCallDelay, 1.0, "Retry call should happen after polling delay (>=1 second)")
        XCTAssertLessThan(retryCallDelay, 1.2, "Retry call should happen within reasonable time (<=1.2 seconds)")
    }

    func testSetupIntentPollingBehaviorWithTimeoutThenSuccess() {
        let mockAPIClient = STPAPIClientPollingMock()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let pollingBudget = PollingBudget(startDate: Date(), duration: 1.0)
        let expectation = self.expectation(description: "SetupIntent polling completes after timeout retry")

        var callTimes: [Date] = []
        let startTime = Date()

        let setupIntent = STPFixtures.setupIntent(
            paymentMethodTypes: ["card"],
            status: .processing,
            paymentMethod: ["id": "pm_test", "type": "card"]
        )

        mockAPIClient.retrieveSetupIntentHandler = { _, _, completion in
            callTimes.append(Date())

            if callTimes.count == 1 {
                // First call: simulate timeout error
                let timeoutError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorTimedOut,
                    userInfo: [NSLocalizedDescriptionKey: "The request timed out."]
                )
                completion(nil, timeoutError)
            } else {
                // Second call: return success
                let responseDict = setupIntent.allResponseFields.merging([
                    "status": STPSetupIntentStatus.string(from: .succeeded)
                ]) { _, new in new }

                let succeededSI = STPSetupIntent.decodedObject(fromAPIResponse: responseDict)
                completion(succeededSI, nil)
                expectation.fulfill()
            }
        }

        let currentAction = STPPaymentHandlerSetupIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: self,
            threeDSCustomizationSettings: STPThreeDSCustomizationSettings(),
            setupIntent: setupIntent,
            returnURL: nil
        ) { _, _, _ in }

        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction, pollingBudget: pollingBudget)

        wait(for: [expectation], timeout: 15.0)

        XCTAssertEqual(callTimes.count, 2, "Expected exactly 2 network calls: initial timeout + retry success")

        let firstCallDelay = callTimes[0].timeIntervalSince(startTime)
        let retryCallDelay = callTimes[1].timeIntervalSince(startTime)

        XCTAssertLessThan(firstCallDelay, 0.1, "First call should happen immediately")
        XCTAssertGreaterThan(retryCallDelay, 1.0, "Retry call should happen after polling delay (>=1 second)")
        XCTAssertLessThan(retryCallDelay, 1.2, "Retry call should happen within reasonable time (<=1.2 seconds)")
    }

    func testSetupIntentPollingBehaviorWithFinalCall() {
        let mockAPIClient = STPAPIClientPollingMock()
        let paymentHandler = STPPaymentHandler(apiClient: mockAPIClient)
        let pollingBudget = PollingBudget(startDate: Date(), duration: 1.0)
        let expectation = self.expectation(description: "SetupIntent polling completes with final call")

        var callTimes: [Date] = []
        let startTime = Date()

        let setupIntent = STPFixtures.setupIntent(
            paymentMethodTypes: ["card"],
            status: .processing,
            paymentMethod: ["id": "pm_test", "type": "card", "created": 12345]
        )

        mockAPIClient.retrieveSetupIntentHandler = { _, _, completion in
            callTimes.append(Date())
            let status: STPSetupIntentStatus = callTimes.count >= 2 ? .succeeded : .processing

            let responseDict = setupIntent.allResponseFields.merging([
                "status": STPSetupIntentStatus.string(from: status)
            ]) { _, new in new }

            let updatedSI = STPSetupIntent.decodedObject(fromAPIResponse: responseDict)

            // Simulate 1.1-second network request time for first request
            DispatchQueue.main.asyncAfter(deadline: .now() + (callTimes.count == 1 ? 1.1 : 0.0)) {
                completion(updatedSI, nil)

                if callTimes.count >= 2 {
                    expectation.fulfill()
                }
            }
        }

        let currentAction = STPPaymentHandlerSetupIntentActionParams(
            apiClient: mockAPIClient,
            authenticationContext: self,
            threeDSCustomizationSettings: STPThreeDSCustomizationSettings(),
            setupIntent: setupIntent,
            returnURL: nil
        ) { _, _, _ in }

        paymentHandler.currentAction = currentAction
        paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction, pollingBudget: pollingBudget)

        wait(for: [expectation], timeout: 30.0)

        XCTAssertEqual(callTimes.count, 2, "Expected exactly 2 network calls: initial + final")

        let firstCallDelay = callTimes[0].timeIntervalSince(startTime)
        let finalCallDelay = callTimes[1].timeIntervalSince(startTime)

        XCTAssertLessThan(firstCallDelay, 1.0, "First call should happen immediately")
        XCTAssertGreaterThan(finalCallDelay, 1.1, "Final call should happen after polling budget expires")
        XCTAssertLessThan(finalCallDelay, 1.3, "Final call should happen after polling budget expires but within a reasonable time")
    }
}

class STPPaymentHandlerTests: APIStubbedTestCase {

    func testPaymentHandlerRetriesWithBackoff() {
        let oldMaxRetries = StripeAPI.maxRetries
        StripeAPI.maxRetries = 1
        STPPaymentHandler.sharedHandler.apiClient = stubbedAPIClient()

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("3ds2/authenticate") ?? false
        } response: { _ in
            let jsonText = """
                        {
                            "state": "challenge_required",
                            "livemode": "false",
                            "ares" : {
                                "dsTransID": "4e4750e7-6ab5-45a4-accf-9c668ed3b5a7",
                                "acsTransID": "fa695a82-a48c-455d-9566-a652058dda27",
                                "p_messageVersion": "1.0.5",
                                "acsOperatorID": "acsOperatorUL",
                                "sdkTransID": "D77EB83F-F317-4E29-9852-EBAAB55515B7",
                                "eci": "00",
                                "dsReferenceNumber": "3DS_LOA_DIS_PPFU_020100_00010",
                                "acsReferenceNumber": "3DS_LOA_ACS_PPFU_020100_00009",
                                "threeDSServerTransID": "fc7a39de-dc41-4b65-ba76-a322769b2efc",
                                "messageVersion": "2.2.0",
                                "authenticationValue": "AABBCCDDEEFFAABBCCDDEEFFAAA=",
                                "messageType": "pArs",
                                "transStatus": "C",
                                "acsChallengeMandated": "NO"
                            }
                        }
                """
            return HTTPStubsResponse(
                data: jsonText.data(using: .utf8)!,
                statusCode: 200,
                headers: nil
            )
        }

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("3ds2/challenge_complete") ?? false
        } response: { _ in
            let errorResponse = [
                "error":
                    [
                        "message": "This is intentionally failing for this test.",
                        "type": "invalid_request_error",
                    ],
            ]
            return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 400, headers: nil)
        }

        // Stub the fetch SetupIntent request, which should be called after the failed challenge_complete
        let fetchedSetupIntentExpectation = expectation(description: "Fetched SetupIntent")
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("setup_intents/seti_123") ?? false
        } response: { _ in
            fetchedSetupIntentExpectation.fulfill()
            return HTTPStubsResponse(jsonObject: STPTestUtils.jsonNamed("SetupIntent")!, statusCode: 400, headers: nil)
        }

        let paymentHandlerExpectation = expectation(
            description: "paymentHandlerFinished"
        )
        var inProgress = true

        // Meaningless cert, generated for this test
        // Expires 3/2/2121: Apologies to future engineers!
        let cert = """
            MIIBijCB9AIBATANBgkqhkiG9w0BAQUFADANMQswCQYDVQQGEwJVUzAgFw0yMTAz
            MjYxODQyNDVaGA8yMTIxMDMwMjE4NDI0NVowDTELMAkGA1UEBhMCVVMwgZ8wDQYJ
            KoZIhvcNAQEBBQADgY0AMIGJAoGBAL6rIW6t+8eo1exqhvYt8H1vM+TyHNNychlD
            hILw745yXZQAy9ByRG3euYEydE3SFINgWBCUuwWmkNfsZUW7Uci1PBMglBFHJrE8
            8ZvtuJgnPkqmu97a9JkyROiaqAmqoMDP95HiZG5i3a1E/QPpPyYA3VJ/El17Qqkl
            aHN32qzjAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEAUhxbGQ5sQMDUqFTvibU7RzqL
            dTaFhdjTDBu5YeIbXXUrJSG2AydXRq7OacRksnQhvNYXimfcgfse46XQG7rKUCfj
            kbazRiRxMZylTz8zbePAFcVq6zxJ+RBVrv51D+/JgbCcQ50nZiocllR0J9UL8CKZ
            obaUC2OjBbSuCZwF8Ig=
            """
        let rootCA = """
            MIIBkDCB+gIJAJ3pmjFOkxTXMA0GCSqGSIb3DQEBBQUAMA0xCzAJBgNVBAYTAlVT
            MB4XDTIxMDMyNjE4NDEzMVoXDTIyMDMyNjE4NDEzMVowDTELMAkGA1UEBhMCVVMw
            gZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAKmFDGPV77Fk/wgUMwbxjQk+bpUY
            cTjNBsjK3xMaUWeE17Sry6IguO1iWaXVey9YJ1Dm83PNO/5i9nHh3gmFhEJmc55T
            g+0tZQigjTcs5/BfmWtrfPYIWqKvIJqkkHrIEJnwavAS5OFGyDArHLwUtsgJbDmW
            tIeQg3EH/8BSWR0BAgMBAAEwDQYJKoZIhvcNAQEFBQADgYEATY2aQvZZJLPgUr1/
            oDvRy6KZ6p7n3+jXF8DNvVOIaQRD4Ndk5NfStteIT5XvzfmD6QqpG3nlJ6Wy3oSP
            03KvO4GWIyP9cuP/QLaEmxJIYKwPrdxLkUHFfzyy8tN54xOWPxN4Up9gVN6pSdVk
            KWrsPfhPs3G57wir370Q69lV/8A=
            """
        let iauss = STPIntentActionUseStripeSDK(
            encryptionInfo: [
                "certificate": cert,
                "directory_server_id": "0000000000",
                "root_certificate_authorities": [rootCA],
            ],
            directoryServerName: "none",
            directoryServerKeyID: "none",
            serverTransactionID: "none",
            threeDSSourceID: "none",
            publishableKeyOverride: nil,
            threeDS2IntentOverride: nil,
            allResponseFields: [:]
        )
        let action = STPIntentAction(
            type: .useStripeSDK,
            redirectToURL: nil,
            alipayHandleRedirect: nil,
            useStripeSDK: iauss,
            oxxoDisplayDetails: nil,
            weChatPayRedirectToApp: nil,
            boletoDisplayDetails: nil,
            verifyWithMicrodeposits: nil,
            cashAppRedirectToApp: nil,
            payNowDisplayQrCode: nil,
            konbiniDisplayDetails: nil,
            promptPayDisplayQrCode: nil,
            swishHandleRedirect: nil,
            multibancoDisplayDetails: nil,
            allResponseFields: [:]
        )
        let setupIntent = STPSetupIntent(
            stripeID: "test",
            automaticPaymentMethods: nil,
            clientSecret: "seti_123_secret_123",
            created: Date(),
            customerID: nil,
            stripeDescription: nil,
            livemode: false,
            nextAction: action,
            paymentMethodID: "test",
            paymentMethod: nil,
            paymentMethodOptions: nil,
            paymentMethodTypes: [],
            status: .requiresAction,
            usage: .none,
            lastSetupError: nil,
            allResponseFields: [:]
        )

        // We expect this request to retry a few times with exponential backoff before calling the completion handler.
        STPPaymentHandler.sharedHandler._handleNextAction(
            for: setupIntent,
            with: self,
            returnURL: nil
        ) { (status, _, _) in
            XCTAssertEqual(status, .failed)
            inProgress = false
            paymentHandlerExpectation.fulfill()
        }

        let checkedStillInProgress = expectation(
            description: "Checked that we're still in progress after 2s"
        )
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
            // Make sure we're still in progress after 2 seconds
            // This shows that we're retrying the 3DS2 request a few times
            // while applying an appropriate amount of backoff.
            XCTAssertEqual(inProgress, true)
            checkedStillInProgress.fulfill()
        }

        wait(for: [paymentHandlerExpectation, checkedStillInProgress, fetchedSetupIntentExpectation], timeout: 60)
        STPPaymentHandler.sharedHandler.apiClient = STPAPIClient.shared
        StripeAPI.maxRetries = oldMaxRetries
    }
}

// MARK: - Mock Classes
class STPAPIClientPollingMock: STPAPIClient {
    var retrievePaymentIntentHandler: ((String, [String]?, @escaping STPPaymentIntentCompletionBlock) -> Void)?
    var retrieveSetupIntentHandler: ((String, [String]?, @escaping STPSetupIntentCompletionBlock) -> Void)?

    override func retrievePaymentIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPPaymentIntentCompletionBlock) {
        retrievePaymentIntentHandler?(secret, expand, completion)
    }

    override func retrieveSetupIntent(withClientSecret secret: String, expand: [String]?, timeout: NSNumber?, completion: @escaping STPSetupIntentCompletionBlock) {
        retrieveSetupIntentHandler?(secret, expand, completion)
    }
}

extension STPPaymentHandlerTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}

extension STPPaymentHandlerStubbedTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
