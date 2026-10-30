//
//  STPFixtures.swift
//  StripePaymentsTestUtils
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePayments

public let STPTestJSONCustomer = "Customer"
public let STPTestJSONCard = "Card"
public let STPTestJSONPaymentIntent = "PaymentIntent"
public let STPTestJSONSetupIntent = "SetupIntent"
public let STPTestJSONPaymentMethodCard = "CardPaymentMethod"
public let STPTestJSONPaymentMethodApplePay = "ApplePayPaymentMethod"
public let STPTestJSONPaymentMethodBacsDebit = "BacsDebitPaymentMethod"
public let STPTestJSONSourceBankAccount = "BankAccount"
public let STPTestJSONSource3DS = "3DSSource"
public let STPTestJSONSourceAlipay = "AlipaySource"
public let STPTestJSONSourceBancontact = "BancontactSource"
public let STPTestJSONSourceCard = "CardSource"
public let STPTestJSONSourceEPS = "EPSSource"
public let STPTestJSONSourceiDEAL = "iDEALSource"
public let STPTestJSONSourceMultibanco = "MultibancoSource"
public let STPTestJSONSourceP24 = "P24Source"
public let STPTestJSONSourceSEPADebit = "SEPADebitSource"
public let STPTestJSONSourceWeChatPay = "WeChatPaySource"

public class STPFixtures: NSObject {
    /// An STPConnectAccountParams object with ToS accepted.
    public class func accountParams() -> STPConnectAccountParams {
        let params = STPConnectAccountIndividualParams()
        return STPConnectAccountParams(tosShownAndAccepted: true, individual: params)!
    }

    /// An address.
    public class func address() -> STPAddress {
        let address = STPAddress()
        address.name = "Jenny Rosen"
        address.phone = "5555555555"
        address.email = "jrosen@example.com"
        address.line1 = "27 Smith St"
        address.line2 = "Apt 2"
        address.postalCode = "10001"
        address.city = "New York"
        address.state = "NY"
        address.country = "US"
        return address
    }

    /// A bank account params object.
    public class func bankAccountParams() -> STPBankAccountParams {
        let bankParams = STPBankAccountParams()
        // https://stripe.com/docs/testing#account-numbers
        bankParams.accountNumber = "000123456789"
        bankParams.routingNumber = "110000000"
        bankParams.country = "US"
        bankParams.currency = "usd"
        bankParams.accountNumber = "Jenny Rosen"
        return bankParams
    }

    /// A valid card params object.
    public class func cardParams() -> STPCardParams {
        let cardParams = STPCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 10
        cardParams.expYear = 99
        cardParams.cvc = "123"
        return cardParams
    }

    /// A valid PaymentMethod card params object.
    public class func paymentMethodCardParams() -> STPPaymentMethodCardParams {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 10
        cardParams.expYear = 50
        cardParams.cvc = "123"
        return cardParams
    }

    /// A Card object.
    public class func card() -> STPCard {
        return STPCard.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONCard))!
    }

    /// A PaymentIntent object.
    public class func paymentIntent() -> STPPaymentIntent {
        return STPPaymentIntent.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONPaymentIntent))!
    }

    /// A SetupIntent object.
    public class func setupIntent() -> STPSetupIntent {
        return STPSetupIntent.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSetupIntent))!
    }

    /// A PKPaymentRequest with a single summary item.
    public class func applePayRequest() -> PKPaymentRequest {
        let paymentRequest = StripeAPI.paymentRequest(
            withMerchantIdentifier: "foo",
            country: "US",
            currency: "USD"
        )
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "10.00")),
        ]
        return paymentRequest
    }

    /// A PKPayment from the Apple Pay simulator, with a shipping contact.
    public class func simulatorApplePayPayment() -> PKPayment {
        let payment = PKPayment()
        let paymentToken = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()
        // These properties are read-only, so set them through their Objective-C setters.
        paymentMethod.perform(NSSelectorFromString("setDisplayName:"), with: "Simulated Instrument")
        paymentMethod.perform(NSSelectorFromString("setNetwork:"), with: "AmEx")
        paymentToken.perform(NSSelectorFromString("setTransactionIdentifier:"), with: "Simulated Identifier")
        paymentToken.perform(NSSelectorFromString("setPaymentMethod:"), with: paymentMethod)
        payment.perform(NSSelectorFromString("setToken:"), with: paymentToken)

        // Add shipping
        let shipping = PKContact()
        shipping.name = PersonNameComponentsFormatter().personNameComponents(from: "Jane Doe")
        let address = CNMutablePostalAddress()
        address.street = "510 Townsend St"
        shipping.postalAddress = address
        payment.perform(NSSelectorFromString("setShippingContact:"), with: shipping)
        return payment
    }

    /// A PKPayment with real (expired) token data and a billing contact.
    public class func applePayPayment() -> PKPayment {
        let payment = PKPayment()
        let paymentToken = PKPaymentToken()
        let tokenDataString =
            #"{"version":"EC_v1","data":"lF8RBjPvhc2GuhjEh7qFNijDJjxD/ApmGdQhgn8tpJcJDOwn2E1BkOfSvnhrR8BUGT6+zeBx8OocvalHZ5ba/WA/tDxGhcEcOMp8sIJrXMVcJ6WqT"#
            + #"5P1ZY+utmdORhxyH4nUw2wuEY4lAE7/GtEU/RNDhaKx/m93l0oLlk84qD1ynTA5JP3gjkdX+RK23iCAZDScXCcCU0OnYlJV8sDyf3+8hIo0gpN43AxoY6N1xAsVbGsO4ZjSCahaXbgt0"#
            + #"egFug3s7Fyt9W4uzu07SKKCA2+DNZeZeerefpN1d1YbiCNlxFmffZKLCGdFERc7Ci3+yrHWWnYhKdQh8FeKCiiAvY5gbZJgQ91lNumCuP1IkHdHqxYI0qFk9c2R6KStJDtoUbVEYbxwn"#
            + #"GdEJJPiMPjuKlgi7E+LlBdXiREmlz4u1EA=","signature":"MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgEFADCABgkqhkiG9w0BBwEAAKCAMIID4jCCA4igAwIBAg"#
            + #"IIJEPyqAad9XcwCgYIKoZIzj0EAwIwejEuMCwGA1UEAwwlQXBwbGUgQXBwbGljYXRpb24gSW50ZWdyYXRpb24gQ0EgLSBHMzEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdX"#
            + #"Rob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMB4XDTE0MDkyNTIyMDYxMVoXDTE5MDkyNDIyMDYxMVowXzElMCMGA1UEAwwcZWNjLXNtcC1icm9rZXItc2lnbl"#
            + #"9VQzQtUFJPRDEUMBIGA1UECwwLaU9TIFN5c3RlbXMxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEwhV37evWx7Ihj2jdcJ"#
            + #"ChIY3HsL1vLCg9hGCV2Ur0pUEbg0IO2BHzQH6DMx8cVMP36zIg1rrV1O/0komJPnwPE6OCAhEwggINMEUGCCsGAQUFBwEBBDkwNzA1BggrBgEFBQcwAYYpaHR0cDovL29jc3AuYXBwbG"#
            + #"UuY29tL29jc3AwNC1hcHBsZWFpY2EzMDEwHQYDVR0OBBYEFJRX22/VdIGGiYl2L35XhQfnm1gkMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUI/JJxE+T5O8n5sT2KGw/orv9Lkswgg"#
            + #"EdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2"#
            + #"VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZCB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbi"#
            + #"BwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3dy5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcm"#
            + #"wuYXBwbGUuY29tL2FwcGxlYWljYTMuY3JsMA4GA1UdDwEB/wQEAwIHgDAPBgkqhkiG92NkBh0EAgUAMAoGCCqGSM49BAMCA0gAMEUCIHKKnw+Soyq5mXQr1V62c0BXKpaHodYu9TWXEP"#
            + #"UWPpbpAiEAkTecfW6+W5l0r0ADfzTCPq2YtbS39w01XIayqBNy8bEwggLuMIICdaADAgECAghJbS+/OpjalzAKBggqhkjOPQQDAjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRz"#
            + #"MxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0xNDA1MDYyMzQ2MzBaFw0yOTA1MDYyMzQ2Mz"#
            + #"BaMHoxLjAsBgNVBAMMJUFwcGxlIEFwcGxpY2F0aW9uIEludGVncmF0aW9uIENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcH"#
            + #"BsZSBJbmMuMQswCQYDVQQGEwJVUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPAXEYQZ12SF1RpeJYEHduiAou/ee65N4I38S5PhM1bVZls1riLQl3YNIk57ugj9dhfOiMt2u2Zwvs"#
            + #"joKYT/VEWjgfcwgfQwRgYIKwYBBQUHAQEEOjA4MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDA0LWFwcGxlcm9vdGNhZzMwHQYDVR0OBBYEFCPyScRPk+TvJ+"#
            + #"bE9ihsP6K7/S5LMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUu7DeoVgziJqkipnevr3rr9rLJKswNwYDVR0fBDAwLjAsoCqgKIYmaHR0cDovL2NybC5hcHBsZS5jb20vYXBwbG"#
            + #"Vyb290Y2FnMy5jcmwwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAg4EAgUAMAoGCCqGSM49BAMCA2cAMGQCMDrPcoNRFpmxhvs1w1bKYr/0F+3ZD3VNoo6+8ZyBXkK3ifiY95tZn5"#
            + #"jVQQ2PnenC/gIwMi3VRCGwowV3bF3zODuQZ/0XfCwhbZZPxnJpghJvVPh6fRuZy5sJiSFhBpkPCZIdAAAxggFeMIIBWgIBATCBhjB6MS4wLAYDVQQDDCVBcHBsZSBBcHBsaWNhdGlvbi"#
            + #"BJbnRlZ3JhdGlvbiBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMCCCRD8qgGnfV3MA"#
            + #"0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTQxMjIyMDIxMzQyWjAvBgkqhkiG9w0BCQQxIgQgUak8LCvAswLOnY2vlZf/iG"#
            + #"3q04omAr3zV8YTtqvORGYwCgYIKoZIzj0EAwIERjBEAiAuPXMqEQqiTjYadOAvNmohP2yquB4owoQNjuAETkFXMAIgcH6zOxnbTTFmlEocqMztWR+L6OVBH6iTPIFMBNPcq6gAAAAAAA"#
            + #"A=","header":{"transactionId":"a530c7d68b6a69791d8864df2646c8aa3d09d33b56d8f8162ab23e1b26afe5e9","ephemeralPublicKey":"MFkwEwYHKoZIzj0CAQYIK"#
            + #"oZIzj0DAQcDQgAEhKpIc6wTNQGy39bHM0a0qziDb20jMBFZT9XKSdjGULpDGRdyil6MLwMyIf3lQxaV/P7CQztw28IvYozvKvjBPQ==","publicKeyHash":"yRcyn7njT6JL3AY9nm"#
            + #"g0KD/xm/ch7gW1sGl2OuEucZY="}}"#
        let data = tokenDataString.data(using: .utf8)

        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "Test"
        nameComponents.familyName = "Testerson"
        let contact = PKContact()
        contact.name = nameComponents

        // These properties are read-only, so set them through their Objective-C setters.
        // Add a fake display name
        let paymentMethod = PKPaymentMethod()
        paymentMethod.perform(NSSelectorFromString("setDisplayName:"), with: "Master Charge")
        paymentToken.perform(NSSelectorFromString("setPaymentMethod:"), with: paymentMethod)
        paymentToken.perform(NSSelectorFromString("setPaymentData:"), with: data)
        payment.perform(NSSelectorFromString("setToken:"), with: paymentToken)
        payment.perform(NSSelectorFromString("setBillingContact:"), with: contact)
        return payment
    }

    // MARK: - Payment Method

    /// A card PaymentMethod object.
    public class func paymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJSON())!
    }

    /// A card PaymentMethod JSON dictionary.
    public class func paymentMethodJSON() -> [AnyHashable: Any] {
        return STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard)!
    }

    /// An Apple Pay PaymentMethod object.
    public class func applePayPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: applePayPaymentMethodJSON())!
    }

    /// An Apple Pay PaymentMethod JSON dictionary.
    public class func applePayPaymentMethodJSON() -> [AnyHashable: Any] {
        return STPTestUtils.jsonNamed(STPTestJSONPaymentMethodApplePay)!
    }

    /// A bank account PaymentMethod object.
    public class func bankAccountPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: bankAccountPaymentMethodJSON())!
    }

    /// A bank account PaymentMethod JSON dictionary.
    public class func bankAccountPaymentMethodJSON() -> [AnyHashable: Any] {
        return STPTestUtils.jsonNamed(STPTestJSONSourceBankAccount)!
    }
}
