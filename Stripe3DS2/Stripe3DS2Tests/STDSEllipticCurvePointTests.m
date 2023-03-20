//
//  STDSEllipticCurvePointTests.m
//  Stripe3DS2Tests
//
//  Created by Cameron Sabol on 4/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "NSString+JWEHelpers.h"
#import "STDSEllipticCurvePoint.h"

@interface STDSEllipticCurvePointTests : XCTestCase

@end

@implementation STDSEllipticCurvePointTests

- (void)testInitWithJWK {

    STDSEllipticCurvePoint *ecPoint = [[STDSEllipticCurvePoint alloc] initWithJWK:@{ // ref. EMVCo_3DS_-AppBased_CryptoExamples_082018.pdf
                                                                                    @"kty":@"EC",
                                                                                    @"crv":@"P-256",
                                                                                    @"x":@"mPUKT_bAWGHIhg0TpjjqVsP1rXWQu_vwVOHHtNkdYoA",
                                                                                    @"y":@"8BQAsImGeAS46fyWw5MhYfGTT0IjBpFw2SS34Dv4Irs",
                                                                                    }];

    XCTAssertNotNil(ecPoint, @"Failed to create point with valid jwk");
    XCTAssertEqualObjects(ecPoint.x, [@"mPUKT_bAWGHIhg0TpjjqVsP1rXWQu_vwVOHHtNkdYoA" _stds_base64URLDecodedData], @"Parsed incorrect x-coordinate");
    XCTAssertEqualObjects(ecPoint.y, [@"8BQAsImGeAS46fyWw5MhYfGTT0IjBpFw2SS34Dv4Irs" _stds_base64URLDecodedData], @"Parsed incorrect y-coordinate");

    ecPoint = [[STDSEllipticCurvePoint alloc] initWithJWK:@{
                                                            @"kty":@"EC",
                                                            @"crv":@"P-128",
                                                            @"x":@"mPUKT_bAWGHIhg0TpjjqVsP1rXWQu_vwVOHHtNkdYoA",
                                                            @"y":@"8BQAsImGeAS46fyWw5MhYfGTT0IjBpFw2SS34Dv4Irs",
                                                            }];
    XCTAssertNil(ecPoint, @"Shoud return nil for non P-256 curve.");
}

@end
