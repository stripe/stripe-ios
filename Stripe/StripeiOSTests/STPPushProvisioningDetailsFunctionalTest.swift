//
//  STPPushProvisioningDetailsFunctionalTest.swift
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/30/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Stripe

import OHHTTPStubs
import OHHTTPStubsSwift
@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPushProvisioningDetailsFunctionalTest: APIStubbedTestCase {

    func testRetrievePushProvisioningDetails() {
        // this API requires a secret key - replace the key below if you need to re-record the network traffic.
        let client = STPAPIClient(publishableKey: "pk_test_REPLACEME")
        let cardId = "ic_1C0Xig4JYtv6MPZK91WoXa9u"
        let cert1 =
            "MIID/TCCA6OgAwIBAgIIGM2CpiS9WyYwCgYIKoZIzj0EAwIwgYAxNDAyBgNVBAMMK0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zIENBIC0gRzIxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0xODA2MDEyMjE0MTVaFw0yMDA2MzAyMjE0MTVaMGwxMjAwBgNVBAMMKWVjYy1jcnlwdG8tc2VydmljZXMtZW5jaXBoZXJtZW50X1VDNi1QUk9EMRQwEgYDVQQLDAtpT1MgU3lzdGVtczETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASzCVyQGX3syyW2aI6nyfNQe+vjjzjU4rLO0ZiWiVZZSmEzYfACFI8tuDFiDLv9XWrHEeX0/yNtGVjwAzpanWb/o4ICGDCCAhQwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBSEtoTMOoZichZZlOgao71I3zrfCzBHBggrBgEFBQcBAQQ7MDkwNwYIKwYBBQUHMAGGK2h0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDMtYXBwbGV3d2RyY2EyMDUwggEdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZCB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbiBwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3dy5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxld3dkcmNhMi5jcmwwHQYDVR0OBBYEFI5aYtQKaJCRpvI1Dgh+Ra4x2iCrMA4GA1UdDwEB/wQEAwIDKDASBgkqhkiG92NkBicBAf8EAgUAMAoGCCqGSM49BAMCA0gAMEUCIAY/9gwN/KAAw3EtW3NyeX1UVM3fO+wVt0cbeHL8eM/mAiEAppLm5O/2Ox8uHkxI4U/kU5vDhJA21DRbzm2rsYN+EcQ="
        let cert2 =
            "MIIC9zCCAnygAwIBAgIIb+/Y9emjp+4wCgYIKoZIzj0EAwIwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNTA2MjM0MzI0WhcNMjkwNTA2MjM0MzI0WjCBgDE0MDIGA1UEAwwrQXBwbGUgV29ybGR3aWRlIERldmVsb3BlciBSZWxhdGlvbnMgQ0EgLSBHMjEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE3fC3BkvP3XMEE8RDiQOTgPte9nStQmFSWAImUxnIYyIHCVJhysTZV+9tJmiLdJGMxPmAaCj8CWjwENrp0C7JGqOB9zCB9DBGBggrBgEFBQcBAQQ6MDgwNgYIKwYBBQUHMAGGKmh0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDQtYXBwbGVyb290Y2FnMzAdBgNVHQ4EFgQUhLaEzDqGYnIWWZToGqO9SN863wswDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBS7sN6hWDOImqSKmd6+veuv2sskqzA3BgNVHR8EMDAuMCygKqAohiZodHRwOi8vY3JsLmFwcGxlLmNvbS9hcHBsZXJvb3RjYWczLmNybDAOBgNVHQ8BAf8EBAMCAQYwEAYKKoZIhvdjZAYCDwQCBQAwCgYIKoZIzj0EAwIDaQAwZgIxANmxxzHGI/ZPTdDZR8V9GGkRh3En02it4Jtlmr5s3z9GppAJvm6hOyywUYlBPIfSvwIxAPxkUolLPF2/axzCiZgvcq61m6oaCyNUd1ToFUOixRLal1BzfF7QbrJcYlDXUfE6Wg=="
        let nonce = "ea85a73a"
        let nonceSignature =
            "QBfCqTvDhmRcwqxJF3fDqzhXezIpwrpHFcOMw7/DvGVBwpfCuicwwqHCmMKYMD06w754wrjChcObwqjDr8K9wqxxUydQaMOyfsKGZMK4AcKMwqNfwoHDlcKLHsO5w7JqQiHDln7Du8KUNMOnwqpGwq/CqcKswo1Lw7s="
        let certs: [Data] = [
            Data(base64Encoded: cert1, options: [])!,
            Data(base64Encoded: cert2, options: [])!,
        ]
        let expectation = self.expectation(description: "Push provisioning details")

        stub { urlRequest in
            return urlRequest.url?.absoluteString.contains("/v1/issuing/cards/ic_1C0Xig4JYtv6MPZK91WoXa9u/push_provisioning_details") ?? false
        } response: { _ in
            let pushDetailsResponseJSON = """
                {
                  "activation_data" : "TUJQQUMtMS1GSy00MDU1NTEuMS0tVERFQS1FNUVCNUJCQjhGMENDMjdCQjU5MUNCRTdCMTVDN0U2RjBENTQ5RDM1NkZERTRDQUZBNDBGOUNCMTA1MzI5NUQ4N0RBRTk0MTE0QTQyNENDQTY0NDAxRTFCQTExOTRBRDM=",
                  "object" : "issuing.push_provisioning_details",
                  "ephemeral_public_key" : "BHdLb5BNpoPrh9Btay8LwQ5oELoziQwJL7HagE3xB5mrbdgLa5iiwogu34Y32\\/xBEviaN31s\\/ONRXSetYT745ig=",
                  "card" : "ic_1C0Xig4JYtv6MPZK91WoXa9u",
                  "contents" : "UYeMxRqiYrjVzwqKcCGRVbgFXRspbDIKkWWly8e55caWkHYmO2DNnFtqD3y5S6bvGbe+bkNPCIkT1UzQQChCQOkb0P+cbVDBLaFGaDeJW0Mhca8\\/6GwbUx9lp4H3czqszG504PkiA89dNvnbtwUmlQOpk+B\\/IAMnkaXjD2xUBUtPX9xEr5EvckkDSHHFmpy5rbGfqnWsPbJNPwUiE+6mYbt643DqF9RpmgdFN84DImuMU1W0xshbkN7voq63L\\/6UgTW7liTzWVzKUT36TtaTw5TGKVf1Niqu5CHNu2NpDEnzrvcwUCgphxRVgezJyFfq1NjhZVlGA2nUKZuRvc\\/XjBwdE0fr4Enw5XfHbRQHorpv\\/S2rX4Cmn4VHJE1JDHWK3Wrn4HmMOCH+psVi+T5hPvy6+\\/v+0zRRmGGeFKQEx0soItHiQauN2\\/zO4QoC2DCQOAKGj1KSzqHhTgdxBcBu4TIOQRsIXu6zk1ItenHIdq4thD8vF8m3wgJ8Y3KcG3TwwgbjomxOjO4rX0AA9q2V6w0TXWQ1eWC8WfX11J30Zt\\/SbyYHoU8KrIdM2ANcOvIFHENnUNBcL7AO0+tjv9lVO7M9w7hKMiVJOnDGMeH2OQfnTBOJI8SEHGm2kDRNw\\/5+VGJ7pHA1wZ9y2IS6EvY8IeNhqZ7HdBXhn18X4AWThZqmNvGuZoEU\\/ZlPmfed\\/c0BgqSw5x6K9GuC5G9Nyee3O1E6wETf4Z3goNbFnRYNJ8m+A4DxUKbvhhRSNva4d\\/lRkoNuQj2ztPiLSAPVt1H7Dk3ryeyXCrqprHsjn5T35jXFOlm5whuyeGgeXWt3DUxsYXZGTiohZyU3bZELqW3EUSwjwQ=="
                }
                """
            return HTTPStubsResponse(data: pushDetailsResponseJSON.data(using: .utf8)!, statusCode: 200, headers: nil)
        }

        let params = STPPushProvisioningDetailsParams(
            cardId: "ic_1C0Xig4JYtv6MPZK91WoXa9u",
            certificates: certs,
            nonce: Data(base64Encoded: nonce, options: [])!,
            nonceSignature: Data(base64Encoded: nonceSignature, options: [])!
        )
        // To re-record this test, get an ephemeral key for the above Issuing card and pass that instead of [STPFixtures ephemeralKey]
        let ephemeralKey = STPFixtures.ephemeralKey()
        client.retrievePushProvisioningDetails(with: params, ephemeralKey: ephemeralKey) {
            details,
            error in
            expectation.fulfill()
            XCTAssertNil(error)
            XCTAssert((details?.cardId == cardId))
            XCTAssertEqual(details, details)
        }
        waitForExpectations(timeout: 5.0, handler: nil)
    }
}
