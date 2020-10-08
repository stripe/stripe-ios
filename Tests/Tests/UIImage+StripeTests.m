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
    // Strategy is to grab an image from our bundle and pass to the resizer
    // with maximums both larger and smaller than it already is
    // then make sure we get what we expect

    UIImage *testImage = [STPImageLibrary safeImageNamed:@"stp_shipping_form.png"
                                     templateIfAvailable:NO];

    static const NSUInteger kBiggerSize = 50000;
    static const NSUInteger kSmallerSize = 6000;
    static const NSUInteger kMuchSmallerSize = 5000; // don't make this too low or test becomes somewhat meaningless, as jpegs can only get so small


    // Verify that before being passed to resizer it is within the
    // correct size range for our tests to be meaningful
    NSData *data = UIImageJPEGRepresentation(testImage, 0.5);
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < kBiggerSize);
    XCTAssertTrue(data.length > kSmallerSize);
    XCTAssertTrue(data.length > kMuchSmallerSize);

    // Test passing in a maxBytes larger than original image
    data = [testImage stp_jpegDataWithMaxFileSize:kBiggerSize];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < kBiggerSize);
    UIImage *resizedImage = [UIImage imageWithData:data scale:testImage.scale];
    // Image shouldn't have been shrunk at all
    XCTAssertTrue(CGSizeEqualToSize(resizedImage.size, testImage.size));

    // Test passing in a maxBytes a bit smaller than the original image
    data = [testImage stp_jpegDataWithMaxFileSize:kSmallerSize];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < kSmallerSize);

    // Test passing in a maxBytes a lot smaller than the original image
    data = [testImage stp_jpegDataWithMaxFileSize:kMuchSmallerSize];
    XCTAssertNotNil(data);
    XCTAssertTrue(data.length < kMuchSmallerSize);
}

@end
