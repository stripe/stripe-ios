//
//  UIImage+StripeTests.m
//  Stripe
//
//  Created by Brian Dorfman on 4/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "UIImage+Stripe.h"
#import "STPImageLibrary+Private.h"

@interface UIImage_StripeTests : XCTestCase

@end

@implementation UIImage_StripeTests

- (void)testJpegImageResizing {
    // Strategy is to grab an image from our bundle and resize it to
    // both smaller and bigger size than it already is and make sure we get
    // what we expect

    UIImage *testImage = [STPImageLibrary safeImageNamed:@"stp_shipping_form@3x.png"
                                     templateIfAvailable:NO];

    NSData *data = nil;
    data = [testImage jpegDataWithMaxFileSize:50000];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < 50000);

    data = [testImage jpegDataWithMaxFileSize:10000];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < 10000);

    data = [testImage jpegDataWithMaxFileSize:1000];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < 1000);
}

@end
