//
//  STDSBase64URLEncodingTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 3/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSData+JWEHelpers.h"
#import "NSString+JWEHelpers.h"

@interface STDSBase64URLEncodingTests : XCTestCase

@end

@implementation STDSBase64URLEncodingTests

// test cases from https://tools.ietf.org/html/draft-ietf-jose-json-web-signature-41

- (void)testEncodingDataToString {
    {
        Byte bytes[5] = {3, 236, 255, 224, 193};
        NSData *data = [NSData dataWithBytes:bytes length:5];
        XCTAssertEqualObjects([data _stds_base64URLEncodedString], @"A-z_4ME");
    }

    {
        Byte bytes[30] = {123, 34, 116, 121, 112, 34, 58, 34, 74, 87, 84, 34, 44, 13, 10, 32, 34, 97, 108, 103, 34, 58, 34, 72, 83, 50, 53, 54, 34, 125};
        NSData *data = [NSData dataWithBytes:bytes length:30];
        XCTAssertEqualObjects([data _stds_base64URLEncodedString], @"eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9");
    }

    {
        Byte bytes[70] = {123, 34, 105, 115, 115, 34, 58, 34, 106, 111, 101, 34, 44, 13, 10,
            32, 34, 101, 120, 112, 34, 58, 49, 51, 48, 48, 56, 49, 57, 51, 56,
            48, 44, 13, 10, 32, 34, 104, 116, 116, 112, 58, 47, 47, 101, 120, 97,
            109, 112, 108, 101, 46, 99, 111, 109, 47, 105, 115, 95, 114, 111,
            111, 116, 34, 58, 116, 114, 117, 101, 125};
        NSData *data = [NSData dataWithBytes:bytes length:70];
        XCTAssertEqualObjects([data _stds_base64URLEncodedString], @"eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ");
    }

}

- (void)testEncodingString {
    XCTAssertEqualObjects([@"{\"typ\":\"JWT\",\r\n \"alg\":\"HS256\"}" _stds_base64URLEncodedString], @"eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9");

    XCTAssertEqualObjects([@"{\"iss\":\"joe\",\r\n \"exp\":1300819380,\r\n \"http://example.com/is_root\":true}"  _stds_base64URLEncodedString], @"eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ");
}

- (void)testDecodingString {
    XCTAssertEqualObjects([@"eyJ0eXAiOiJKV1QiLA0KICJhbGciOiJIUzI1NiJ9" _stds_base64URLDecodedString], @"{\"typ\":\"JWT\",\r\n \"alg\":\"HS256\"}");

    XCTAssertEqualObjects([ @"eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ" _stds_base64URLDecodedString], @"{\"iss\":\"joe\",\r\n \"exp\":1300819380,\r\n \"http://example.com/is_root\":true}");
}

@end
