//
//  STPIntentActionTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPIntentAction+Private.h"
#import "STPIntentActionRedirectToURL.h"

@interface STPIntentActionTest : XCTestCase

@end

@implementation STPIntentActionTest

- (void)testDecodedObjectFromAPIResponseRedirectToURL {
    STPIntentAction *(^decode)(NSDictionary *) = ^STPIntentAction *(NSDictionary * dict) {
        return [STPIntentAction decodedObjectFromAPIResponse:dict];
    };

    XCTAssertNil(decode(nil));
    XCTAssertNil(decode(@{}));
    XCTAssertNil(decode(@{ @"redirect_to_url": @{@"url": @"http://stripe.com"} }),
                 @"fails without type");

    STPIntentAction *missingDetails = decode(@{
                                                            @"type": @"redirect_to_url"
                                                            });
    XCTAssertNotNil(missingDetails);
    XCTAssertEqual(missingDetails.type, STPIntentActionTypeUnknown,
                   @"Type becomes unknown if the redirect_to_url details are missing");

    STPIntentAction *badURL = decode(@{
                                                    @"type": @"redirect_to_url",
                                                    @"redirect_to_url": @{
                                                            @"url": @"not a url"
                                                            }
                                                    });
    XCTAssertNotNil(badURL);
    XCTAssertEqual(badURL.type, STPIntentActionTypeUnknown,
                   @"Type becomes unknown if the redirect_to_url details don't have a valid URL");

    STPIntentAction *missingReturnURL = decode(@{
                                                              @"type": @"redirect_to_url",
                                                              @"redirect_to_url": @{
                                                                      @"url": @"https://stripe.com/"
                                                                      }
                                                              });
    XCTAssertNotNil(missingReturnURL);
    XCTAssertEqual(missingReturnURL.type, STPIntentActionTypeRedirectToURL,
                   @"Missing return_url won't prevent it from decoding");
    XCTAssertNotNil(missingReturnURL.redirectToURL.url);
    XCTAssertEqualObjects(missingReturnURL.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(missingReturnURL.redirectToURL.returnURL);

    STPIntentAction *badReturnURL = decode(@{
                                                          @"type": @"redirect_to_url",
                                                          @"redirect_to_url": @{
                                                                  @"url": @"https://stripe.com/",
                                                                  @"return_url": @"not a url"
                                                                  }
                                                          });
    XCTAssertNotNil(badReturnURL);
    XCTAssertEqual(badReturnURL.type, STPIntentActionTypeRedirectToURL,
                   @"invalid return_url won't prevent it from decoding");
    XCTAssertNotNil(badReturnURL.redirectToURL.url);
    XCTAssertEqualObjects(badReturnURL.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(badReturnURL.redirectToURL.returnURL);


    STPIntentAction *complete = decode(@{
                                                              @"type": @"redirect_to_url",
                                                              @"redirect_to_url": @{
                                                                      @"url": @"https://stripe.com/",
                                                                      @"return_url": @"my-app://payment-complete"
                                                                      }
                                                              });
    XCTAssertNotNil(complete);
    XCTAssertEqual(complete.type, STPIntentActionTypeRedirectToURL);
    XCTAssertNotNil(complete.redirectToURL.url);
    XCTAssertEqualObjects(complete.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNotNil(complete.redirectToURL.returnURL);
    XCTAssertEqualObjects(complete.redirectToURL.returnURL,
                          [NSURL URLWithString:@"my-app://payment-complete"]);
}

- (void)testActionFromString {
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"redirect_to_url"],
                   STPIntentActionTypeRedirectToURL);
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"REDIRECT_TO_URL"],
                   STPIntentActionTypeRedirectToURL);
    
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"use_stripe_sdk"],
                   STPIntentActionTypeUseStripeSDK);
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"USE_STRIPE_SDK"],
                   STPIntentActionTypeUseStripeSDK);
    
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"garbage"],
                   STPIntentActionTypeUnknown);
    XCTAssertEqual([STPIntentAction actionTypeFromString:@"GARBAGE"],
                   STPIntentActionTypeUnknown);
}

@end
