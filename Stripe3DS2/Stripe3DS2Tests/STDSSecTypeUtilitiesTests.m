//
//  STDSSecTypeUtilitiesTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+JWEHelpers.h"
#import "STDSSecTypeUtilities.h"

@interface STDSSecTypeUtilitiesTests : XCTestCase

@end

@implementation STDSSecTypeUtilitiesTests

- (void)testDirectoryServerForID {
    XCTAssertEqual(STDSDirectoryServerForID(@"ul_test"), STDSDirectoryServerSTPTestRSA, @"ul_test should map to STDSDirectoryServerSTPTestRSA.");
    XCTAssertEqual(STDSDirectoryServerForID(@"ec_test"), STDSDirectoryServerSTPTestEC, @"ec_test should map to STDSDirectoryServerSTPTestEC.");
    XCTAssertEqual(STDSDirectoryServerForID(@"F055545342"), STDSDirectoryServerULTestRSA, @"F055545342 should map to STDSDirectoryServerULTestRSA.");
    XCTAssertEqual(STDSDirectoryServerForID(@"F155545342"), STDSDirectoryServerULTestEC, @"F155545342 should map to STDSDirectoryServerULTestEC.");

    XCTAssertEqual(STDSDirectoryServerForID(@"junk"), STDSDirectoryServerUnknown, @"junk server ID should map to STDSDirectoryServerUnknown.");
}

- (void)testCertificateForServer {
    SecCertificateRef certificate = NULL;

    certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestRSA);
    XCTAssertTrue(certificate != NULL, @"Unable to load STDSDirectoryServerSTPTestRSA certificate.");
    if (certificate != NULL) {
        CFRelease(certificate);
    }
    certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestEC);
    XCTAssertTrue(certificate != NULL, @"Unable to load STDSDirectoryServerSTPTestEC certificate.");
    if (certificate != NULL) {
        CFRelease(certificate);
    }
    certificate = STDSCertificateForServer(STDSDirectoryServerUnknown);
    if (certificate != NULL) {
        XCTFail(@"Should not have an unknown certificate.");
        CFRelease(certificate);
    }
}

- (void)testCopyPublicRSAKey {
    SecCertificateRef certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestRSA);
    if (certificate != NULL) {
        SecKeyRef publicKey = SecCertificateCopyKey(certificate);
        if (publicKey != NULL) {
            CFRelease(publicKey);
        } else {
            XCTFail(@"Unable to load public key from certificate");
        }

        CFRelease(certificate);
    } else {
        XCTFail(@"Failed loading certificate for %@", NSStringFromSelector(_cmd));
    }
}

- (void)testCopyPublicECKey {
    SecCertificateRef certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestEC);
    if (certificate != NULL) {
        SecKeyRef publicKey = SecCertificateCopyKey(certificate);
        if (publicKey != NULL) {
            CFRelease(publicKey);
        } else {
            XCTFail(@"Unable to load public key from certificate");
        }

        CFRelease(certificate);
    } else {
        XCTFail(@"Failed loading certificate for %@", NSStringFromSelector(_cmd));
    }
}

- (void)testCopyKeyTypeRSA {
    SecCertificateRef certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestRSA);
    if (certificate != NULL) {
        CFStringRef keyType = STDSSecCertificateCopyPublicKeyType(certificate);
        if (keyType != NULL) {
            XCTAssertTrue(CFStringCompare(keyType, kSecAttrKeyTypeRSA, 0) == kCFCompareEqualTo, @"Key type is incorrect");
            CFRelease(keyType);
        } else {
            XCTFail(@"Failed to copy key type.");
        }
        CFRelease(certificate);
    } else {
        XCTFail(@"Failed loading certificate for %@", NSStringFromSelector(_cmd));
    }
}

- (void)testCopyKeyTypeEC {
    SecCertificateRef certificate = STDSCertificateForServer(STDSDirectoryServerSTPTestEC);
    if (certificate != NULL) {
        CFStringRef keyType = STDSSecCertificateCopyPublicKeyType(certificate);
        if (keyType != NULL) {
            XCTAssertTrue(CFStringCompare(keyType, kSecAttrKeyTypeECSECPrimeRandom, 0) == kCFCompareEqualTo, @"Key type is incorrect");
            CFRelease(keyType);
        } else {
            XCTFail(@"Failed to copy key type.");
        }
        CFRelease(certificate);
    } else {
        XCTFail(@"Failed loading certificate for %@", NSStringFromSelector(_cmd));
    }
}

- (void)testRandomData {
    // We're not actually going to implement randomness tests... just sanity
    NSData *data1 = STDSCryptoRandomData(32);
    NSData *data2 = STDSCryptoRandomData(32);

    XCTAssertNotNil(data1);
    XCTAssertTrue(data1.length == 32, @"Random data is not correct length.");
    XCTAssertNotEqualObjects(data1, data2, @"Sanity check: two random data's should not equate to equal (unless you get reeeeallly unlucky.");
    XCTAssertTrue(STDSCryptoRandomData(12).length == 12, @"Random data is not correct length.");
    XCTAssertNotNil(STDSCryptoRandomData(0), @"Empty random data should return empty data.");
    XCTAssertTrue(STDSCryptoRandomData(0).length == 0, @"Empty random data should have length 0");
}

- (void)testConcatKDFWithSHA256 {
    NSData *data = STDSCreateConcatKDFWithSHA256(STDSCryptoRandomData(32), 256, @"acs_identifier");
    XCTAssertNotNil(data, @"Failed to concat KDF and hash.");
    XCTAssertEqual(data.length, 256, @"Concat returned data of incorrect length");
}


- (void)testVerifyEllipticCurveP256 {
    NSData *payload = [@"eyJhbGciOiJFUzI1NiJ9.eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *signature = [@"DtEhU3ljbEg8L38VWAfUAqOyKAM6-Xx-F4GawxaepmXFCgfTjDxw5djxLa8ISlSApmWQxfKTUJqPP3-Kg6NU1Q" _stds_base64URLDecodedData];

    NSData *coordinateX = [@"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU" _stds_base64URLDecodedData];
    NSData *coordinateY = [@"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0" _stds_base64URLDecodedData];

    XCTAssertTrue(STDSVerifyEllipticCurveP256Signature(coordinateX, coordinateY, payload, signature));
}
@end
