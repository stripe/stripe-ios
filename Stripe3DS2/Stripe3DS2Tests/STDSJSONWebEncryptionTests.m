//
//  STDSJSONWebEncryptionTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 1/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STDSStripe3DS2Error.h"
#import "NSString+JWEHelpers.h"
#import "STDSDirectoryServer.h"
#import "STDSDirectoryServerCertificate.h"
#import "STDSJSONWebEncryption.h"
#import "STDSSecTypeUtilities.h"

@interface STDSJSONWebEncryptionTests : XCTestCase

@end

@implementation STDSJSONWebEncryptionTests

- (void)testEncryption {
    NSDictionary *json = @{@"a": @(0), @"b": @[@(0), @(1), @(2)], @"c": @{@"d": @"val"}};
    NSError *error = nil;

    NSString *encrypted = [STDSJSONWebEncryption encryptJSON:json forDirectoryServer:STDSDirectoryServerSTPTestRSA error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with ul_test cert.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");

    encrypted = [STDSJSONWebEncryption encryptJSON:json forDirectoryServer:STDSDirectoryServerSTPTestEC error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with ec_test cert.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");

    encrypted = [STDSJSONWebEncryption encryptJSON:json forDirectoryServer:STDSDirectoryServerULTestRSA error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with STDSDirectoryServerULTestRSA.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");

    encrypted = [STDSJSONWebEncryption encryptJSON:json forDirectoryServer:STDSDirectoryServerULTestEC error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with STDSDirectoryServerULTestEC.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");

    encrypted = [STDSJSONWebEncryption encryptJSON:json forDirectoryServer:STDSDirectoryServerUnknown error:&error];
    XCTAssertNil(encrypted, @"Invalid server ID should return nil.");
    XCTAssertEqual(error.code, STDSErrorCodeDecryptionVerification, @"Failed encryption should provide a STDSErrorCodeDecryptionVerification error.");
}

- (void)testEncryptionWithCustomCertificate {
    NSDictionary *json = @{@"a": @(0), @"b": @[@(0), @(1), @(2)], @"c": @{@"d": @"val"}};
    NSError *error = nil;
    // Using ds-amex.pm.PEM
    NSString *certificateString = @"MIIE0TCCA7mgAwIBAgIUXbeqM1duFcHk4dDBwT8o7Ln5wX8wDQYJKoZIhvcNAQEL"
    "BQAwXjELMAkGA1UEBhMCVVMxITAfBgNVBAoTGEFtZXJpY2FuIEV4cHJlc3MgQ29t"
    "cGFueTEsMCoGA1UEAxMjQW1lcmljYW4gRXhwcmVzcyBTYWZla2V5IElzc3Vpbmcg"
    "Q0EwHhcNMTgwMjIxMjM0OTMxWhcNMjAwMjIxMjM0OTMwWjCB0DELMAkGA1UEBhMC"
    "VVMxETAPBgNVBAgTCE5ldyBZb3JrMREwDwYDVQQHEwhOZXcgWW9yazE/MD0GA1UE"
    "ChM2QW1lcmljYW4gRXhwcmVzcyBUcmF2ZWwgUmVsYXRlZCBTZXJ2aWNlcyBDb21w"
    "YW55LCBJbmMuMTkwNwYDVQQLEzBHbG9iYWwgTmV0d29yayBUZWNobm9sb2d5IC0g"
    "TmV0d29yayBBUEkgUGxhdGZvcm0xHzAdBgNVBAMTFlNESy5TYWZlS2V5LkVuY3J5"
    "cHRLZXkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDSFF9kTYbwRrxX"
    "C6WcJJYio5TZDM62+CnjQRfggV3GMI+xIDtMIN8LL/jbWBTycu97vrNjNNv+UPhI"
    "WzhFDdUqyRfrY337A39uE8k1xhdDI3dNeZz6xgq8r9hn2NBou78YPBKidpN5oiHn"
    "TxcFq1zudut2fmaldaa9a4ZKgIQo+02heiJfJ8XNWkoWJ17GcjJ59UU8C1KF/y1G"
    "ymYO5ha2QRsVZYI17+ZFsqnpcXwK4Mr6RQKV6UimmO0nr5++CgvXfekcWAlLV6Xq"
    "juACWi3kw0haepaX/9qHRu1OSyjzWNcSVZ0On6plB5Lq6Y9ylgmxDrv+zltz3MrT"
    "K7txIAFFAgMBAAGjggESMIIBDjAMBgNVHRMBAf8EAjAAMCEGA1UdEQQaMBiCFlNE"
    "Sy5TYWZlS2V5LkVuY3J5cHRLZXkwRQYJKwYBBAGCNxQCBDgeNgBBAE0ARQBYAF8A"
    "UwBBAEYARQBLAEUAWQAyAF8ARABTAF8ARQBOAEMAUgBZAFAAVABJAE8ATjAOBgNV"
    "HQ8BAf8EBAMCBJAwHwYDVR0jBBgwFoAU7k/rXuVMhTBxB1zSftPgmLFuDIgwRAYD"
    "VR0fBD0wOzA5oDegNYYzaHR0cDovL2FtZXhzay5jcmwuY29tLXN0cm9uZy1pZC5u"
    "ZXQvYW1leHNhZmVrZXkuY3JsMB0GA1UdDgQWBBQHclVTo5nwZGH8labJ2F2P45xi"
    "fDANBgkqhkiG9w0BAQsFAAOCAQEAWY6b77VBoGLs3k5vOqSU7QRqT+4v6y77T8LA"
    "BKrSZ58DiVZWVyDSxyftQUiRRgFHt2gTN0yfJTP50Fyp84nCEWC0tugZ4iIhgPss"
    "HzL+4/u4eG/MTzK2ESxvPgr6YHajyuU+GXA89u8+bsFrFmojOjhTgFKli7YUeV/0"
    "xoiYZf2utlns800ofJrcrfiFoqE6PvK4Od0jpeMgfSKv71nK5ihA1+wTk76ge1fs"
    "PxL23hEdRpWW11ofaLfJGkLFXMM3/LHSXWy7HhsBgDELdzLSHU4VkSv8yTOZxsRO"
    "ByxdC5v3tXGcK56iQdtKVPhFGOOEBugw7AcuRzv3f1GhvzAQZg==";
    STDSDirectoryServerCertificate *certificate = [STDSDirectoryServerCertificate customCertificateWithData:[[NSData alloc] initWithBase64EncodedString:certificateString options:0]];

    NSString *encrypted = [STDSJSONWebEncryption encryptJSON:json
                                             withCertificate:certificate
                                           directoryServerID:@"custom_test"
                                                 serverKeyID:nil
                                                       error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with custom cert.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");
}

- (void)testDirectEncryptionWithKey {
    NSDictionary *json = @{@"a": @(0), @"b": @[@(0), @(1), @(2)], @"c": @{@"d": @"val"}};
    NSError *error = nil;
    NSData *contentEncryptionKey = STDSCryptoRandomData(32);
    NSString *encrypted = [STDSJSONWebEncryption directEncryptJSON:json
                                          withContentEncryptionKey:contentEncryptionKey
                                               forACSTransactionID:@"acs_id"
                                                             error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with direct encryption key.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");
}

- (void)testDecryption {
    NSDictionary *json = @{@"a": @(0), @"b": @[@(0), @(1), @(2)], @"c": @{@"d": @"val"}};
    NSError *error = nil;
    NSData *contentEncryptionKey = STDSCryptoRandomData(32);
    NSString *encrypted = [STDSJSONWebEncryption directEncryptJSON:json
                                          withContentEncryptionKey:contentEncryptionKey
                                               forACSTransactionID:@"acs_id"
                                                             error:&error];
    XCTAssertNotNil(encrypted, @"Should successfully encrypt with direct encryption key.");
    XCTAssertNil(error, @"Successful encryption should not populate error.");
    
    NSDictionary *decrypted = [STDSJSONWebEncryption decryptData:[encrypted dataUsingEncoding:NSUTF8StringEncoding]
                                        withContentEncryptionKey:contentEncryptionKey
                                                           error:&error];
    XCTAssertEqualObjects(decrypted, json, @"Decrypted is not equal to the encrypted json");
}

@end
