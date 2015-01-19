//
//  STPAPIConnectionTest.m
//  Stripe Tests
//
//  Created by Jack Flintermann on 1/8/15.
//
//

#import <XCTest/XCTest.h>
#import "STPAPIConnection.h"

@interface STPAPIConnectionTest : XCTestCase

@end

@implementation STPAPIConnectionTest


- (void)testSHA1FingerprintOfData {
    NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *fingerprint = [STPAPIConnection SHA1FingerprintOfData:data];
    XCTAssertEqualObjects(fingerprint, @"aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d");
}

@end
