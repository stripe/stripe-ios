//
//  STPApplePayTest.m
//  Stripe
//
//  Created by Jack Flintermann on 12/21/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

@import XCTest;
@import PassKit;

#import "STPAPIClient.h"
#import "STPAPIClient+ApplePay.h"

@interface STPApplePayTest : XCTestCase

@end

@implementation STPApplePayTest

- (void)testCreateTokenWithPayment {
    if (![PKPayment class]) {
        return;
    }
    PKPayment *payment = [PKPayment new];
    PKPaymentToken *paymentToken = [PKPaymentToken new];
    NSString *tokenDataString = @"{\"version\":\"EC_v1\",\"data\":\"lF8RBjPvhc2GuhjEh7qFNijDJjxD/ApmGdQhgn8tpJcJDOwn2E1BkOfSvnhrR8BUGT6+zeBx8OocvalHZ5ba/WA/"
        @"tDxGhcEcOMp8sIJrXMVcJ6WqT5P1ZY+utmdORhxyH4nUw2wuEY4lAE7/GtEU/RNDhaKx/"
        @"m93l0oLlk84qD1ynTA5JP3gjkdX+RK23iCAZDScXCcCU0OnYlJV8sDyf3+8hIo0gpN43AxoY6N1xAsVbGsO4ZjSCahaXbgt0egFug3s7Fyt9W4uzu07SKKCA2+"
        @"DNZeZeerefpN1d1YbiCNlxFmffZKLCGdFERc7Ci3+yrHWWnYhKdQh8FeKCiiAvY5gbZJgQ91lNumCuP1IkHdHqxYI0qFk9c2R6KStJDtoUbVEYbxwnGdEJJPiMPjuKlgi7E+"
        @"LlBdXiREmlz4u1EA=\",\"signature\":"
        @"\"MIAGCSqGSIb3DQEHAqCAMIACAQExDzANBglghkgBZQMEAgEFADCABgkqhkiG9w0BBwEAAKCAMIID4jCCA4igAwIBAgIIJEPyqAad9XcwCgYIKoZIzj0EAwIwejEuMCwGA1UEAwwlQXBwbGUgQX"
        @"BwbGljYXRpb24gSW50ZWdyYXRpb24gQ0EgLSBHMzEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMB4XDTE0MD"
        @"kyNTIyMDYxMVoXDTE5MDkyNDIyMDYxMVowXzElMCMGA1UEAwwcZWNjLXNtcC1icm9rZXItc2lnbl9VQzQtUFJPRDEUMBIGA1UECwwLaU9TIFN5c3RlbXMxEzARBgNVBAoMCkFwcGxlIEluYy4xCz"
        @"AJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEwhV37evWx7Ihj2jdcJChIY3HsL1vLCg9hGCV2Ur0pUEbg0IO2BHzQH6DMx8cVMP36zIg1rrV1O/"
        @"0komJPnwPE6OCAhEwggINMEUGCCsGAQUFBwEBBDkwNzA1BggrBgEFBQcwAYYpaHR0cDovL29jc3AuYXBwbGUuY29tL29jc3AwNC1hcHBsZWFpY2EzMDEwHQYDVR0OBBYEFJRX22/"
        @"VdIGGiYl2L35XhQfnm1gkMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUI/JJxE+T5O8n5sT2KGw/orv9LkswggEdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/"
        @"jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZ"
        @"CB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbiBwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3d"
        @"y5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDQGA1UdHwQtMCswKaAnoCWGI2h0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxlYWljYTMuY3JsMA4GA1UdDwEB/"
        @"wQEAwIHgDAPBgkqhkiG92NkBh0EAgUAMAoGCCqGSM49BAMCA0gAMEUCIHKKnw+Soyq5mXQr1V62c0BXKpaHodYu9TWXEPUWPpbpAiEAkTecfW6+"
        @"W5l0r0ADfzTCPq2YtbS39w01XIayqBNy8bEwggLuMIICdaADAgECAghJbS+/"
        @"OpjalzAKBggqhkjOPQQDAjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQsw"
        @"CQYDVQQGEwJVUzAeFw0xNDA1MDYyMzQ2MzBaFw0yOTA1MDYyMzQ2MzBaMHoxLjAsBgNVBAMMJUFwcGxlIEFwcGxpY2F0aW9uIEludGVncmF0aW9uIENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENl"
        @"cnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABPAXEYQZ12SF1RpeJYEHduiAou/"
        @"ee65N4I38S5PhM1bVZls1riLQl3YNIk57ugj9dhfOiMt2u2ZwvsjoKYT/"
        @"VEWjgfcwgfQwRgYIKwYBBQUHAQEEOjA4MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDA0LWFwcGxlcm9vdGNhZzMwHQYDVR0OBBYEFCPyScRPk+TvJ+bE9ihsP6K7/"
        @"S5LMA8GA1UdEwEB/"
        @"wQFMAMBAf8wHwYDVR0jBBgwFoAUu7DeoVgziJqkipnevr3rr9rLJKswNwYDVR0fBDAwLjAsoCqgKIYmaHR0cDovL2NybC5hcHBsZS5jb20vYXBwbGVyb290Y2FnMy5jcmwwDgYDVR0PAQH/"
        @"BAQDAgEGMBAGCiqGSIb3Y2QGAg4EAgUAMAoGCCqGSM49BAMCA2cAMGQCMDrPcoNRFpmxhvs1w1bKYr/0F+3ZD3VNoo6+8ZyBXkK3ifiY95tZn5jVQQ2PnenC/gIwMi3VRCGwowV3bF3zODuQZ/"
        @"0XfCwhbZZPxnJpghJvVPh6fRuZy5sJiSFhBpkPCZIdAAAxggFeMIIBWgIBATCBhjB6MS4wLAYDVQQDDCVBcHBsZSBBcHBsaWNhdGlvbiBJbnRlZ3JhdGlvbiBDQSAtIEczMSYwJAYDVQQLDB1BcH"
        @"BsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMCCCRD8qgGnfV3MA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQ"
        @"EHATAcBgkqhkiG9w0BCQUxDxcNMTQxMjIyMDIxMzQyWjAvBgkqhkiG9w0BCQQxIgQgUak8LCvAswLOnY2vlZf/"
        @"iG3q04omAr3zV8YTtqvORGYwCgYIKoZIzj0EAwIERjBEAiAuPXMqEQqiTjYadOAvNmohP2yquB4owoQNjuAETkFXMAIgcH6zOxnbTTFmlEocqMztWR+L6OVBH6iTPIFMBNPcq6gAAAAAAAA=\","
        @"\"header\":{\"transactionId\":\"a530c7d68b6a69791d8864df2646c8aa3d09d33b56d8f8162ab23e1b26afe5e9\",\"ephemeralPublicKey\":"
        @"\"MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhKpIc6wTNQGy39bHM0a0qziDb20jMBFZT9XKSdjGULpDGRdyil6MLwMyIf3lQxaV/"
        @"P7CQztw28IvYozvKvjBPQ==\",\"publicKeyHash\":\"yRcyn7njT6JL3AY9nmg0KD/xm/ch7gW1sGl2OuEucZY=\"}}";
    NSData *data = [tokenDataString dataUsingEncoding:NSUTF8StringEncoding];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [paymentToken performSelector:@selector(setPaymentData:) withObject:data];
    [payment performSelector:@selector(setToken:) withObject:paymentToken];
#pragma clang diagnostic pop

    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_vOo1umqsYxSrP5UXfOeL3ecm"];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Apple pay token creation"];
    [client createTokenWithPayment:payment
                        completion:^(STPToken *token, NSError *error) {
                            [expectation fulfill];
                            XCTAssertNil(token, @"token should be nil");
                            XCTAssertNotNil(error, @"error should not be nil");

                            // Since we can't actually generate a new cryptogram in a CI environment, we should just post a blob of expired token data and
                            // make sure we get the "too long since tokenization" error. This at least asserts that our blob has been correctly formatted and
                            // can be decrypted by the backend.
                            XCTAssert([error.localizedDescription rangeOfString:@"too long"].location != NSNotFound,
                                      @"Error is unrelated to 24-hour expiry: %@",
                                      error.localizedDescription);
                        }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

- (void)testCanSubmitPaymentRequestReturnsYES {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertTrue([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestReturnsNOIfTotalIsZero {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.merchantIdentifier = @"foo";
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

- (void)testCanSubmitPaymentRequestReturnsNOIfMerchantIdentifierIsNil {
    PKPaymentRequest *request = [[PKPaymentRequest alloc] init];
    request.paymentSummaryItems = @[[PKPaymentSummaryItem summaryItemWithLabel:@"bar" amount:[NSDecimalNumber decimalNumberWithString:@"1.00"]]];

    XCTAssertFalse([Stripe canSubmitPaymentRequest:request]);
}

@end
