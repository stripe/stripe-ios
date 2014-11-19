//
//  STPAPIConnectionTest.m
//  Stripe
//
//  Created by Jack Flintermann on 11/15/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
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
