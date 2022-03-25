//
//  STPPaymentHandlerTests.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
import Foundation
import StripeCoreTestUtils
@testable import Stripe
@testable @_spi(STP) import StripeCore
@testable import Stripe3DS2
import OHHTTPStubs

class STPPaymentHandlerStubbedTests: STPNetworkStubbingTestCase {
    override func setUp() {
        self.recordingMode = false;
        super.setUp()
    }
    
    func testCanPresentErrorsAreReported() {
        let createPaymentIntentExpectation = expectation(
            description: "createPaymentIntentExpectation")
        var retrievedClientSecret: String? = nil
        STPTestingAPIClient.shared().createPaymentIntent(withParams: nil) {
            (createdPIClientSecret, error) in
            if let createdPIClientSecret = createdPIClientSecret {
                retrievedClientSecret = createdPIClientSecret
                createPaymentIntentExpectation.fulfill()
            } else {
                XCTFail()
            }
        }
        wait(for: [createPaymentIntentExpectation], timeout: 8)  // STPTestingNetworkRequestTimeout
        guard let clientSecret = retrievedClientSecret,
              let currentYear = Calendar.current.dateComponents([.year], from: Date()).year
        else {
            XCTFail()
            return
        }

        let expiryYear = NSNumber(value: currentYear + 2)
        let expiryMonth = NSNumber(1)

        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4000000000003220"
        cardParams.expYear = expiryYear
        cardParams.expMonth = expiryMonth
        cardParams.cvc = "123"

        let address = STPPaymentMethodAddress()
        address.postalCode = "12345"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams.paramsWith(
            card: cardParams, billingDetails: billingDetails, metadata: nil)

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPAPIClient.shared.publishableKey = "pk_test_ErsyMEOTudSjQR8hh0VrQr5X008sBXGOu6" // STPTestingDefaultPublishableKey

        let paymentHandlerExpectation = expectation(description: "paymentHandlerExpectation")
        STPPaymentHandler.shared().checkCanPresentInTest = true
        STPPaymentHandler.shared().confirmPayment(paymentIntentParams, with: self) { (status, paymentIntent, error) in
            XCTAssertTrue(status == .failed)
            XCTAssertNotNil(paymentIntent)
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.userInfo[STPError.errorMessageKey] as? String, "authenticationPresentingViewController is not in the window hierarchy. You should probably return the top-most view controller instead.")
            paymentHandlerExpectation.fulfill()
        }
        // 2*STPTestingNetworkRequestTimeout payment handler needs to make an ares for this
        // test in addition to fetching the payment intent
        wait(for: [paymentHandlerExpectation], timeout: 2*8)
    }
}

class STPPaymentHandlerTests: APIStubbedTestCase {
    
    func testPaymentHandlerRetriesWithBackoff() {
        STPPaymentHandler.sharedHandler.apiClient = stubbedAPIClient()
        
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("3ds2/authenticate") ?? false
        } response: { urlRequest in
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
                    "messageVersion": "2.1.0",
                    "authenticationValue": "AABBCCDDEEFFAABBCCDDEEFFAAA=",
                    "messageType": "pArs",
                    "transStatus": "C",
                    "acsChallengeMandated": "NO"
                }
            }
    """
            return HTTPStubsResponse(data: jsonText.data(using: .utf8)!, statusCode: 200, headers: nil)
        }
        
        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("3ds2/challenge_complete") ?? false
        } response: { urlRequest in
            let errorResponse = ["error":
                                    ["message": "This is intentionally failing for this test.",
                                     "type": "invalid_request_error"]]
            return HTTPStubsResponse(jsonObject: errorResponse, statusCode: 400, headers: nil)
        }
        
        let paymentHandlerExpectation = expectation(
                description: "paymentHandlerFinished")
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
        let iauss = STPIntentActionUseStripeSDK(encryptionInfo: ["certificate": cert, "directory_server_id": "0000000000", "root_certificate_authorities": [rootCA]], directoryServerName: "none", directoryServerKeyID: "none", serverTransactionID: "none", threeDSSourceID: "none", allResponseFields: [:])
        let action = STPIntentAction(type: .useStripeSDK, redirectToURL: nil, alipayHandleRedirect: nil, useStripeSDK: iauss, oxxoDisplayDetails: nil, weChatPayRedirectToApp: nil, boletoDisplayDetails: nil, verifyWithMicrodeposits: nil, allResponseFields: [:])
        let setupIntent = STPSetupIntent(stripeID: "test", clientSecret: "test", created: Date(), customerID: nil, stripeDescription: nil, livemode: false, nextAction: action, orderedPaymentMethodTypes: [], paymentMethodID: "test", paymentMethod: nil, paymentMethodTypes: [], status: .requiresAction, usage: .none, lastSetupError: nil, allResponseFields: [:], unactivatedPaymentMethodTypes: [])
        
        // We expect this request to retry a few times with exponential backoff before calling the completion handler.
        STPPaymentHandler.sharedHandler._handleNextAction(for: setupIntent, with: self, returnURL: nil) { (status, si, error) in
            XCTAssertEqual(status, .failed)
            inProgress = false
            paymentHandlerExpectation.fulfill()
        }
        
        let checkedStillInProgress = expectation(description: "Checked that we're still in progress after 2s")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
            // Make sure we're still in progress after 2 seconds
            // This shows that we're retrying the 3DS2 request a few times
            // while applying an appropriate amount of backoff.
            XCTAssertEqual(inProgress, true)
            checkedStillInProgress.fulfill()
        }
        
        wait(for: [paymentHandlerExpectation, checkedStillInProgress], timeout: 30)
        STPPaymentHandler.sharedHandler.apiClient = STPAPIClient.shared
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
