//
//  STPGenericStripeObjectTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 7/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>



@interface STPGenericStripeObjectTest : XCTestCase

@end

@implementation STPGenericStripeObjectTest

- (void)testDecodedObject {
    XCTAssertNil([STPGenericStripeObject decodedObjectFromAPIResponse:@{}]);

    STPGenericStripeObject *obj = [STPGenericStripeObject decodedObjectFromAPIResponse:@{@"id": @"card_XYZ"}];
    XCTAssertNotNil(obj);
    XCTAssertEqualObjects(obj.stripeId, @"card_XYZ");
}

@end
