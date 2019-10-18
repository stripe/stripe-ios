//
//  STPPushProvisioningDetailsFunctionalTest.m
//  StripeiOS Tests
//
//  Created by Jack Flintermann on 11/30/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "STPAPIClient+PushProvisioning.h"
#import "STPNetworkStubbingTestCase.h"

@interface STPPushProvisioningDetailsFunctionalTest : STPNetworkStubbingTestCase
@end

@implementation STPPushProvisioningDetailsFunctionalTest

- (void)setUp {
    [super setUp];  
}

- (void)testRetrievePushProvisioningDetails {
    // this API requires a secret key - replace the key below if you need to re-record the network traffic.
    STPAPIClient *client = [[STPAPIClient alloc] initWithPublishableKey:@"pk_test_REPLACEME"];
    NSString *cardId = @"ic_1C0Xig4JYtv6MPZK91WoXa9u";
    NSString *cert1 = @"MIID/TCCA6OgAwIBAgIIGM2CpiS9WyYwCgYIKoZIzj0EAwIwgYAxNDAyBgNVBAMMK0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zIENBIC0gRzIxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzAeFw0xODA2MDEyMjE0MTVaFw0yMDA2MzAyMjE0MTVaMGwxMjAwBgNVBAMMKWVjYy1jcnlwdG8tc2VydmljZXMtZW5jaXBoZXJtZW50X1VDNi1QUk9EMRQwEgYDVQQLDAtpT1MgU3lzdGVtczETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASzCVyQGX3syyW2aI6nyfNQe+vjjzjU4rLO0ZiWiVZZSmEzYfACFI8tuDFiDLv9XWrHEeX0/yNtGVjwAzpanWb/o4ICGDCCAhQwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBSEtoTMOoZichZZlOgao71I3zrfCzBHBggrBgEFBQcBAQQ7MDkwNwYIKwYBBQUHMAGGK2h0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDMtYXBwbGV3d2RyY2EyMDUwggEdBgNVHSAEggEUMIIBEDCCAQwGCSqGSIb3Y2QFATCB/jCBwwYIKwYBBQUHAgIwgbYMgbNSZWxpYW5jZSBvbiB0aGlzIGNlcnRpZmljYXRlIGJ5IGFueSBwYXJ0eSBhc3N1bWVzIGFjY2VwdGFuY2Ugb2YgdGhlIHRoZW4gYXBwbGljYWJsZSBzdGFuZGFyZCB0ZXJtcyBhbmQgY29uZGl0aW9ucyBvZiB1c2UsIGNlcnRpZmljYXRlIHBvbGljeSBhbmQgY2VydGlmaWNhdGlvbiBwcmFjdGljZSBzdGF0ZW1lbnRzLjA2BggrBgEFBQcCARYqaHR0cDovL3d3dy5hcHBsZS5jb20vY2VydGlmaWNhdGVhdXRob3JpdHkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxld3dkcmNhMi5jcmwwHQYDVR0OBBYEFI5aYtQKaJCRpvI1Dgh+Ra4x2iCrMA4GA1UdDwEB/wQEAwIDKDASBgkqhkiG92NkBicBAf8EAgUAMAoGCCqGSM49BAMCA0gAMEUCIAY/9gwN/KAAw3EtW3NyeX1UVM3fO+wVt0cbeHL8eM/mAiEAppLm5O/2Ox8uHkxI4U/kU5vDhJA21DRbzm2rsYN+EcQ=";
    NSString *cert2 = @"MIIC9zCCAnygAwIBAgIIb+/Y9emjp+4wCgYIKoZIzj0EAwIwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNTA2MjM0MzI0WhcNMjkwNTA2MjM0MzI0WjCBgDE0MDIGA1UEAwwrQXBwbGUgV29ybGR3aWRlIERldmVsb3BlciBSZWxhdGlvbnMgQ0EgLSBHMjEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE3fC3BkvP3XMEE8RDiQOTgPte9nStQmFSWAImUxnIYyIHCVJhysTZV+9tJmiLdJGMxPmAaCj8CWjwENrp0C7JGqOB9zCB9DBGBggrBgEFBQcBAQQ6MDgwNgYIKwYBBQUHMAGGKmh0dHA6Ly9vY3NwLmFwcGxlLmNvbS9vY3NwMDQtYXBwbGVyb290Y2FnMzAdBgNVHQ4EFgQUhLaEzDqGYnIWWZToGqO9SN863wswDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBS7sN6hWDOImqSKmd6+veuv2sskqzA3BgNVHR8EMDAuMCygKqAohiZodHRwOi8vY3JsLmFwcGxlLmNvbS9hcHBsZXJvb3RjYWczLmNybDAOBgNVHQ8BAf8EBAMCAQYwEAYKKoZIhvdjZAYCDwQCBQAwCgYIKoZIzj0EAwIDaQAwZgIxANmxxzHGI/ZPTdDZR8V9GGkRh3En02it4Jtlmr5s3z9GppAJvm6hOyywUYlBPIfSvwIxAPxkUolLPF2/axzCiZgvcq61m6oaCyNUd1ToFUOixRLal1BzfF7QbrJcYlDXUfE6Wg==";
    NSString *nonce = @"ea85a73a";
    NSString *nonceSignature = @"QBfCqTvDhmRcwqxJF3fDqzhXezIpwrpHFcOMw7/DvGVBwpfCuicwwqHCmMKYMD06w754wrjChcObwqjDr8K9wqxxUydQaMOyfsKGZMK4AcKMwqNfwoHDlcKLHsO5w7JqQiHDln7Du8KUNMOnwqpGwq/CqcKswo1Lw7s=";
    NSArray *certs = @[
                       [[NSData alloc] initWithBase64EncodedString:cert1 options:0],
                       [[NSData alloc] initWithBase64EncodedString:cert2 options:0],
                       ];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Push provisioning details"];
    STPPushProvisioningDetailsParams *params = [STPPushProvisioningDetailsParams paramsWithCardId:@"ic_1C0Xig4JYtv6MPZK91WoXa9u" certificates:certs nonce:[[NSData alloc] initWithBase64EncodedString:nonce options:0] nonceSignature:[[NSData alloc] initWithBase64EncodedString:nonceSignature options:0]];
    [client retrievePushProvisioningDetailsWithParams:params completion:^(STPPushProvisioningDetails * _Nullable details, NSError * _Nullable error) {
        [expectation fulfill];
        XCTAssertNil(error);
        XCTAssert([details.cardId isEqualToString:cardId]);
    }];
    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
