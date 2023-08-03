//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPFixtures.swift
//  Stripe
//
//  Created by Ben Guo on 3/28/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import OCMock
import PassKit
import Stripe
import StripeCore
import StripePayments
import StripePaymentsUI

let STPTestJSONCustomer = "Customer"
let STPTestJSONCard = "Card"
let STPTestJSONPaymentIntent = "PaymentIntent"
let STPTestJSONSetupIntent = "SetupIntent"
let STPTestJSONPaymentMethodCard = "CardPaymentMethod"
let STPTestJSONPaymentMethodApplePay = "ApplePayPaymentMethod"
let STPTestJSONPaymentMethodBacsDebit = "BacsDebitPaymentMethod"
let STPTestJSONSourceBankAccount = "BankAccount"
let STPTestJSONSource3DS = "3DSSource"
let STPTestJSONSourceAlipay = "AlipaySource"
let STPTestJSONSourceBancontact = "BancontactSource"
let STPTestJSONSourceCard = "CardSource"
let STPTestJSONSourceEPS = "EPSSource"
let STPTestJSONSourceGiropay = "GiropaySource"
let STPTestJSONSourceiDEAL = "iDEALSource"
let STPTestJSONSourceMultibanco = "MultibancoSource"
let STPTestJSONSourceP24 = "P24Source"
let STPTestJSONSourceSEPADebit = "SEPADebitSource"
let STPTestJSONSourceSofort = "SofortSource"
let STPTestJSONSourceWeChatPay = "WeChatPaySource"

class STPFixtures: NSObject {
    /// An STPConnectAccountParams object with all of the fields filled in, and
    /// ToS accepted.
    class func accountParams() -> STPConnectAccountParams {
        let params = STPConnectAccountIndividualParams()
        return STPConnectAccountParams(
            tosShownAndAccepted: true,
            individual: params)
    }

    /// An Address object with all fields filled.
    class func address() -> STPAddress {
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

    /// A BankAccountParams object with all fields filled.
    class func bankAccountParams() -> STPBankAccountParams {
        let bankParams = STPBankAccountParams()
        // https://stripe.com/docs/testing#account-numbers
        bankParams.accountNumber = "000123456789"
        bankParams.routingNumber = "110000000"
        bankParams.country = "US"
        bankParams.currency = "usd"
        bankParams.accountNumber = "Jenny Rosen"
        return bankParams
    }

    /// A CardParams object with a valid number, expMonth, expYear, and cvc.
    class func cardParams() -> STPCardParams {
        let cardParams = STPCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = 10
        cardParams.expYear = 99
        cardParams.cvc = "123"
        return cardParams
    }

    /// A STPPaymentMethodCardParams object with a valid number, expMonth, expYear, and cvc.
    class func paymentMethodCardParams() -> STPPaymentMethodCardParams {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.expMonth = NSNumber(value: 10)
        cardParams.expYear = NSNumber(value: 99)
        cardParams.cvc = "123"
        return cardParams
    }

    class func card() -> STPCard {
        return STPCard.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONCard))
    }

    /// A Source object with type card
    class func cardSource() -> STPSource {
        return STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSourceCard))
    }

    /// A Token for a card
    class func cardToken() -> STPToken {
        let cardDict = STPTestUtils.jsonNamed(STPTestJSONCard)
        var tokenDict: [StringLiteralConvertible : StringLiteralConvertible]?
        if let cardDict {
            tokenDict = [
                "id": "id_for_token",
                "object": "token",
                "livemode": NSNumber(value: false),
                "created": NSNumber(value: 1353025450.0),
                "type": "card",
                "used": NSNumber(value: false),
                "card": cardDict
            ]
        }
        return .decodedObject(fromAPIResponse: tokenDict)
    }

    /// A Customer object with an empty sources array.
    class func customerWithNoSources() -> STPCustomer {
        return STPCustomer.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONCustomer))
    }

    /// A Customer object with a single card token in its sources array, and
    /// default_source set to that card token.
    class func customerWithSingleCardTokenSource() -> STPCustomer {
        return STPCustomer.decodedObject(fromAPIResponse: self.customerWithSingleCardTokenSourceJSON())
    }

    /// The JSON data for a Customer with a single card token in its sources array, and
    /// default_source set to that card token.
    class func customerWithSingleCardTokenSourceJSON() -> [AnyHashable : Any] {
        var card1 = STPTestUtils.jsonNamed(STPTestJSONCard)
        card1?["id"] = "card_123"

        var customer = STPTestUtils.jsonNamed(STPTestJSONCustomer)
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = [card1]
        customer?["default_source"] = card1?["id"]
        customer?["sources"] = sources

        return customer ?? [:]
    }

    /// A Customer object with a single card source in its sources array, and
    /// default_source set to that card source.
    class func customerWithSingleCardSourceSource() -> STPCustomer {
        var card1 = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        card1?["id"] = "card_123"

        var customer = STPTestUtils.jsonNamed(STPTestJSONCustomer)
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = [card1]
        customer?["default_source"] = card1?["id"]
        customer?["sources"] = sources

        return .decodedObject(fromAPIResponse: customer)
    }

    /// A Customer object with two cards in its sources array, 
    /// one a token/card type and one a source object type.
    /// default_source is set to the card token.
    class func customerWithCardTokenAndSourceSources() -> STPCustomer {
        var card1 = STPTestUtils.jsonNamed(STPTestJSONCard)
        card1?["id"] = "card_123"

        var card2 = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        card2?["id"] = "src_456"

        var customer = STPTestUtils.jsonNamed(STPTestJSONCustomer)
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = [card1, card2]
        customer?["default_source"] = card1?["id"]
        customer?["sources"] = sources

        return .decodedObject(fromAPIResponse: customer)

    }

    /// A Customer object with a card source, and apple pay card source, and
    /// default_source set to the apple pay source.
    class func customerWithCardAndApplePaySources() -> STPCustomer {
        return STPCustomer.decodedObject(fromAPIResponse: self.customerWithCardAndApplePaySourcesJSON())
    }

    class func customerWithCardAndApplePaySourcesJSON() -> [AnyHashable : Any] {
        var card1 = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        card1?["id"] = "src_apple_pay_123"
        var cardDict = card1?["card"] as? [AnyHashable : Any]
        cardDict?["tokenization_method"] = "apple_pay"
        card1?["card"] = cardDict

        var card2 = STPTestUtils.jsonNamed(STPTestJSONSourceCard)
        card2?["id"] = "src_card_456"

        var customer = STPTestUtils.jsonNamed(STPTestJSONCustomer)
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = [card1, card2]
        customer?["default_source"] = card1?["id"]
        customer?["sources"] = sources

        return customer ?? [:]
    }

    /// A customer object with a sources array that includes the listed json sources
    /// in the order they are listed in the array.
    /// Valid keys are any STPTestJSONSource constants and the STPTestJSONCard constant.
    /// Ids for the sources will be automatically generated and will be equal to a
    /// string that is the index of the array of that source.
    class func customerWithSources(
        fromJSONKeys jsonSourceKeys: [String],
        defaultSource jsonKeyForDefaultSource: String
    ) -> STPCustomer {
        var sourceJSONDicts: [AnyHashable] = []
        var defaultSourceID: String?
        var sourceCount = 0
        for jsonKey in jsonSourceKeys {
            var sourceDict = STPTestUtils.jsonNamed(jsonKey)
            sourceDict?["id"] = "\(NSNumber(value: sourceCount))"
            if jsonKeyForDefaultSource == jsonKey {
                defaultSourceID = sourceDict?["id"] as? String
            }
            sourceCount += 1
            if let sourceDict {
                sourceJSONDicts.append(sourceDict)
            }
        }

        var customer = STPTestUtils.jsonNamed(STPTestJSONCustomer)
        var sources = customer?["sources"] as? [AnyHashable : Any]
        sources?["data"] = sourceJSONDicts
        customer?["default_source"] = defaultSourceID ?? ""
        customer?["sources"] = sources

        return .decodedObject(fromAPIResponse: customer)
    }

    /// A Source object with type iDEAL
    class func iDEALSource() -> STPSource {
        return STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSourceiDEAL))
    }

    /// A Source object with type Alipay
    class func alipaySource() -> STPSource {
        return STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSourceAlipay))
    }

    /// A Source object with type Alipay and a native redirect url
    class func alipaySourceWithNativeURL() -> STPSource {
        var dictionary = STPTestUtils.jsonNamed(STPTestJSONSourceAlipay)
        var detailsDictionary = dictionary?["alipay"] as? [AnyHashable : Any]
        detailsDictionary?["native_url"] = "alipay://test"
        dictionary?["alipay"] = detailsDictionary
        return .decodedObject(fromAPIResponse: dictionary)
    }

    /// A Source object with type WeChat Pay
    class func weChatPaySource() -> STPSource {
        return STPSource.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed(STPTestJSONSourceWeChatPay))
    }

    /// A PaymentIntent object
    class func paymentIntent() -> STPPaymentIntent {
        return (STPPaymentIntent?.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("PaymentIntent")))!
    }

    /// A SetupIntent object
    class func setupIntent() -> STPSetupIntent {
        return STPSetupIntent.decodedObject(fromAPIResponse: STPTestUtils.jsonNamed("SetupIntent"))
    }

    /// A PaymentConfiguration object with a fake publishable key. Use this to avoid
    /// triggering our asserts when publishable key is nil or invalid. All other values
    /// are at their original defaults.
    class func paymentConfiguration() -> STPPaymentConfiguration {
        let config = STPPaymentConfiguration()
        return config
    }

    /// A customer-scoped ephemeral key that expires in 100 seconds.
    class func ephemeralKey() -> STPEphemeralKey {
        var response = STPTestUtils.jsonNamed("EphemeralKey")
        let interval: TimeInterval = 100
        response?["expires"] = NSNumber(value: Date(timeIntervalSinceNow: interval).timeIntervalSince1970)
        return .decodedObject(fromAPIResponse: response)
    }

    /// A customer-scoped ephemeral key that expires in 10 seconds.
    class func expiringEphemeralKey() -> STPEphemeralKey {
        var response = STPTestUtils.jsonNamed("EphemeralKey")
        let interval: TimeInterval = 10
        response?["expires"] = NSNumber(value: Date(timeIntervalSinceNow: interval).timeIntervalSince1970)
        return .decodedObject(fromAPIResponse: response)
    }

    /// A valid PKPaymentRequest with dummy data.
    class func applePayRequest() -> PKPaymentRequest {
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: "USD")
        paymentRequest?.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "10.00"))
        ]
        return paymentRequest!
    }

    class func simulatorApplePayPayment() -> PKPayment {
        let payment = PKPayment()
        let paymentToken = PKPaymentToken()
        let paymentMethod = PKPaymentMethod()
        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wundeclared-selector"
        paymentMethod.perform(#selector(setter: ASAuthorizationPublicKeyCredentialRegistrationRequest.displayName), with: "Simulated Instrument")
        paymentMethod.perform(Selector("setNetwork:"), with: "AmEx")
        paymentToken.perform(Selector("setTransactionIdentifier:"), with: "Simulated Identifier")

        paymentToken.perform(Selector("setPaymentMethod:"), with: paymentMethod)

        payment.perform(Selector("setToken:"), with: paymentToken)

        // Add shipping
        let shipping = PKContact()
        shipping.name = PersonNameComponentsFormatter().personNameComponents(from: "Jane Doe")
        let address = CNMutablePostalAddress()
        address.street = "510 Townsend St"
        shipping.postalAddress = address
        payment.perform(#selector(setter: PKPaymentRequest.shippingContact), with: shipping)
        //#pragma clang diagnostic pop
        return payment
    }

    /// A PKPaymentObject with test payment data.
    class func applePayPayment() -> PKPayment {
        let payment = PKPayment()
        let paymentToken = PKPaymentToken()
        let tokenDataString = """
            {"version":"EC_v1","data":"lF8RBjPvhc2GuhjEh7qFNijDJjxD/ApmGdQhgn8tpJcJDOwn2E1BkOfSvnhrR8BUGT6+zeBx8OocvalHZ5ba/WA/\
            tDxGhcEcOMp8sIJrXMVcJ6WqT5P1ZY+utmdORhxyH4nUw2wuEY4lAE7/GtEU/RNDhaKx/\
            m93l0oLlk84qD1ynTA5JP3gjkdX+RK23iCAZDScXCcCU0OnYlJV8sDyf3+8hIo0gpN43AxoY6N1xAsVbGsO4ZjSCahaXbgt0egFug3s7Fyt9W4uzu07SKKCA2+\
            DNZeZeerefpN1d1YbiCNlxFmffZKLCGdFERc7Ci3+yrHWWnYhKdQh8FeKCiiAvY5gbZJgQ91lNumCuP1IkHdHqxYI0qFk9c2R6KStJDtoUbVEYbxwnGdEJJPiMPjuKlgi7E+\
            LlBdXiREmlz4u1EA=","signature":\
            "MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgEFADCABgkqhkiG9w0BBwEAAKCAMIID4jCCA4igAwIBAgIIJEPyqAad9XcwCgYIKoZIzj0EAwIwejEuMCwGA1UEAwwlQXBwbGUgQX\
            BwbGljYXRpb24gSW50ZWdyYXRpb24gQ0EgLSBHMzEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMB4XDTE0MD\
            kyNTIyMDYxMVoXDTE5MDkyNDIyMDYxMVowXzElMCMGA1UEAwwcZWNjLXNtcC1icm9rZXItc2lnbl9VQzQtUFJPRDEUMBIGA1UECwwLaU9TIFN5c3RlbXMxEzARBgNVBAoMCkFwcGxlIEluYy4xCz\
            AJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEwhV37evWx7Ihj2jdcJChIY3HsL1vLCg9hGCV2Ur0pUEbg0IO2BHzQH6DMx8cVMP36zIg1rrV1O/\
            0komJPnwPE6OCAhEwggINMEUGCCsGAQUFBwEBBDkwNzA1BggrBgEFBQcwAYYpaHR0cDovL29jc3AuYXBwbGUuY29tL29jc3AwNC1hcHBsZWFpY2EzMDEwHQYDVR0OBBYEFJRX22/\
            VdIGGiYl2L35XhQfnm1gkMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUI/JJxE+T5O8n5sT2KGw/orv9LkswggEdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/\
            jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZ\
            CB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbiBwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3d\
            y5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxlYWljYTMuY3JsMA4GA1UdDwEB/\
            wQEAwIHgDAPBgkqhkiG92NkBh0EAgUAMAoGCCqGSM49BAMCA0gAMEUCIHKKnw+Soyq5mXQr1V62c0BXKpaHodYu9TWXEPUWPpbpAiEAkTecfW6+\
            W5l0r0ADfzTCPq2YtbS39w01XIayqBNy8bEwggLuMIICdaADAgECAghJbS+/\
            OpjalzAKBggqhkjOPQQDAjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQsw\
            CQYDVQQGEwJVUzAeFw0xNDA1MDYyMzQ2MzBaFw0yOTA1MDYyMzQ2MzBaMHoxLjAsBgNVBAMMJUFwcGxlIEFwcGxpY2F0aW9uIEludGVncmF0aW9uIENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENl\
            cnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPAXEYQZ12SF1RpeJYEHduiAou/\
            ee65N4I38S5PhM1bVZls1riLQl3YNIk57ugj9dhfOiMt2u2ZwvsjoKYT/\
            VEWjgfcwgfQwRgYIKwYBBQUHAQEEOjA4MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDA0LWFwcGxlcm9vdGNhZzMwHQYDVR0OBBYEFCPyScRPk+TvJ+bE9ihsP6K7/\
            S5LMA8GA1UdEwEB/\
            wQFMAMBAf8wHwYDVR0jBBgwFoAUu7DeoVgziJqkipnevr3rr9rLJKswNwYDVR0fBDAwLjAsoCqgKIYmaHR0cDovL2NybC5hcHBsZS5jb20vYXBwbGVyb290Y2FnMy5jcmwwDgYDVR0PAQH/\
            BAQDAgEGMBAGCiqGSIb3Y2QGAg4EAgUAMAoGCCqGSM49BAMCA2cAMGQCMDrPcoNRFpmxhvs1w1bKYr/0F+3ZD3VNoo6+8ZyBXkK3ifiY95tZn5jVQQ2PnenC/gIwMi3VRCGwowV3bF3zODuQZ/\
            0XfCwhbZZPxnJpghJvVPh6fRuZy5sJiSFhBpkPCZIdAAAxggFeMIIBWgIBATCBhjB6MS4wLAYDVQQDDCVBcHBsZSBBcHBsaWNhdGlvbiBJbnRlZ3JhdGlvbiBDQSAtIEczMSYwJAYDVQQLDB1BcH\
            BsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMCCCRD8qgGnfV3MA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQ\
            EHATAcBgkqhkiG9w0BCQUxDxcNMTQxMjIyMDIxMzQyWjAvBgkqhkiG9w0BCQQxIgQgUak8LCvAswLOnY2vlZf/\
            iG3q04omAr3zV8YTtqvORGYwCgYIKoZIzj0EAwIERjBEAiAuPXMqEQqiTjYadOAvNmohP2yquB4owoQNjuAETkFXMAIgcH6zOxnbTTFmlEocqMztWR+L6OVBH6iTPIFMBNPcq6gAAAAAAAA=",\
            "header":{"transactionId":"a530c7d68b6a69791d8864df2646c8aa3d09d33b56d8f8162ab23e1b26afe5e9","ephemeralPublicKey":\
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhKpIc6wTNQGy39bHM0a0qziDb20jMBFZT9XKSdjGULpDGRdyil6MLwMyIf3lQxaV/\
            P7CQztw28IvYozvKvjBPQ==","publicKeyHash":"yRcyn7njT6JL3AY9nmg0KD/xm/ch7gW1sGl2OuEucZY="}}
            """
        let data = tokenDataString.data(using: .utf8)

        let nameComponents = PersonNameComponents()
        nameComponents.givenName = "Test"
        nameComponents.familyName = "Testerson"
        let contact = PKContact()
        contact.name = nameComponents

        //#pragma clang diagnostic push
        //#pragma clang diagnostic ignored "-Wundeclared-selector"
        // Add a fake display name
        let paymentMethod = PKPaymentMethod()
        paymentMethod.perform(#selector(setter: ASAuthorizationPublicKeyCredentialRegistrationRequest.displayName), with: "Master Charge")

        paymentToken.perform(Selector("setPaymentMethod:"), with: paymentMethod)

        paymentToken.perform(Selector("setPaymentData:"), with: data)
        payment.perform(Selector("setToken:"), with: paymentToken)
        payment.perform(#selector(setter: PKPaymentRequest.billingContact), with: contact)
        //#pragma clang diagnostic pop
        return payment
    }

    /// A PaymentMethod object

    // MARK: - Payment Method

    class func paymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: self.paymentMethodJSON())
    }

    /// A PaymentMethod JSON dictionary
    class func paymentMethodJSON() -> [AnyHashable : Any] {
        return STPTestUtils.jsonNamed(STPTestJSONPaymentMethodCard) ?? [:]
    }

    /// An Apple Pay Payment Method object.
    class func applePayPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: self.applePayPaymentMethodJSON())
    }

    /// An Apple Pay Payment Method JSON dictionary.
    class func applePayPaymentMethodJSON() -> [AnyHashable : Any] {
        return STPTestUtils.jsonNamed(STPTestJSONPaymentMethodApplePay) ?? [:]
    }

    /// Bank account payment method
    class func bankAccountPaymentMethod() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: self.bankAccountPaymentMethodJSON())
    }

    /// Bank account payment payment method JSON Dictionary
    class func bankAccountPaymentMethodJSON() -> [AnyHashable : Any] {
        return STPTestUtils.jsonNamed(STPTestJSONSourceBankAccount) ?? [:]
    }
}

class STPJsonSources: NSObject {
}