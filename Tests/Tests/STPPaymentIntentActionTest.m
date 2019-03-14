//
//  STPPaymentIntentActionTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentIntentAction.h"
#import "STPPaymentIntentActionRedirectToURL.h"

@interface STPPaymentIntentActionTest : XCTestCase

@end

@implementation STPPaymentIntentActionTest

- (void)testDecodedObjectFromAPIResponseRedirectToURL {
    STPPaymentIntentAction *(^decode)(NSDictionary *) = ^STPPaymentIntentAction *(NSDictionary * dict) {
        return [STPPaymentIntentAction decodedObjectFromAPIResponse:dict];
    };

    XCTAssertNil(decode(nil));
    XCTAssertNil(decode(@{}));
    XCTAssertNil(decode(@{ @"redirect_to_url": @{@"url": @"http://stripe.com"} }),
                 @"fails without type");

    STPPaymentIntentAction *missingDetails = decode(@{
                                                            @"type": @"redirect_to_url"
                                                            });
    XCTAssertNotNil(missingDetails);
    XCTAssertEqual(missingDetails.type, STPPaymentIntentActionTypeUnknown,
                   @"Type becomes unknown if the redirect_to_url details are missing");

    STPPaymentIntentAction *badURL = decode(@{
                                                    @"type": @"redirect_to_url",
                                                    @"redirect_to_url": @{
                                                            @"url": @"not a url"
                                                            }
                                                    });
    XCTAssertNotNil(badURL);
    XCTAssertEqual(badURL.type, STPPaymentIntentActionTypeUnknown,
                   @"Type becomes unknown if the redirect_to_url details don't have a valid URL");

    STPPaymentIntentAction *missingReturnURL = decode(@{
                                                              @"type": @"redirect_to_url",
                                                              @"redirect_to_url": @{
                                                                      @"url": @"https://stripe.com/"
                                                                      }
                                                              });
    XCTAssertNotNil(missingReturnURL);
    XCTAssertEqual(missingReturnURL.type, STPPaymentIntentActionTypeRedirectToURL,
                   @"Missing return_url won't prevent it from decoding");
    XCTAssertNotNil(missingReturnURL.redirectToURL.url);
    XCTAssertEqualObjects(missingReturnURL.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(missingReturnURL.redirectToURL.returnURL);

    STPPaymentIntentAction *badReturnURL = decode(@{
                                                          @"type": @"redirect_to_url",
                                                          @"redirect_to_url": @{
                                                                  @"url": @"https://stripe.com/",
                                                                  @"return_url": @"not a url"
                                                                  }
                                                          });
    XCTAssertNotNil(badReturnURL);
    XCTAssertEqual(badReturnURL.type, STPPaymentIntentActionTypeRedirectToURL,
                   @"invalid return_url won't prevent it from decoding");
    XCTAssertNotNil(badReturnURL.redirectToURL.url);
    XCTAssertEqualObjects(badReturnURL.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(badReturnURL.redirectToURL.returnURL);


    STPPaymentIntentAction *complete = decode(@{
                                                              @"type": @"redirect_to_url",
                                                              @"redirect_to_url": @{
                                                                      @"url": @"https://stripe.com/",
                                                                      @"return_url": @"my-app://payment-complete"
                                                                      }
                                                              });
    XCTAssertNotNil(complete);
    XCTAssertEqual(complete.type, STPPaymentIntentActionTypeRedirectToURL);
    XCTAssertNotNil(complete.redirectToURL.url);
    XCTAssertEqualObjects(complete.redirectToURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNotNil(complete.redirectToURL.returnURL);
    XCTAssertEqualObjects(complete.redirectToURL.returnURL,
                          [NSURL URLWithString:@"my-app://payment-complete"]);
}

@end
