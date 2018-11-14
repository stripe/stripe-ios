//
//  STPPaymentIntentSourceActionTest.m
//  StripeiOS Tests
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "STPPaymentIntentSourceAction.h"
#import "STPPaymentIntentSourceActionAuthorizeWithURL.h"

@interface STPPaymentIntentSourceActionTest : XCTestCase

@end

@implementation STPPaymentIntentSourceActionTest

- (void)testDecodedObjectFromAPIResponseAuthorizeWithURL {
    STPPaymentIntentSourceAction *(^decode)(NSDictionary *) = ^STPPaymentIntentSourceAction *(NSDictionary * dict) {
        return [STPPaymentIntentSourceAction decodedObjectFromAPIResponse:dict];
    };

    XCTAssertNil(decode(nil));
    XCTAssertNil(decode(@{}));
    XCTAssertNil(decode(@{ @"authorize_with_url": @{@"url": @"http://stripe.com"} }),
                 @"fails without type");

    STPPaymentIntentSourceAction *missingDetails = decode(@{
                                                            @"type": @"authorize_with_url"
                                                            });
    XCTAssertNotNil(missingDetails);
    XCTAssertEqual(missingDetails.type, STPPaymentIntentSourceActionTypeUnknown,
                   @"Type becomes unknown if the authorize_with_url details are missing");

    STPPaymentIntentSourceAction *badURL = decode(@{
                                                    @"type": @"authorize_with_url",
                                                    @"authorize_with_url": @{
                                                            @"url": @"not a url"
                                                            }
                                                    });
    XCTAssertNotNil(badURL);
    XCTAssertEqual(badURL.type, STPPaymentIntentSourceActionTypeUnknown,
                   @"Type becomes unknown if the authorize_with_url details don't have a valid URL");

    STPPaymentIntentSourceAction *missingReturnURL = decode(@{
                                                              @"type": @"authorize_with_url",
                                                              @"authorize_with_url": @{
                                                                      @"url": @"https://stripe.com/"
                                                                      }
                                                              });
    XCTAssertNotNil(missingReturnURL);
    XCTAssertEqual(missingReturnURL.type, STPPaymentIntentSourceActionTypeAuthorizeWithURL,
                   @"Missing return_url won't prevent it from decoding");
    XCTAssertNotNil(missingReturnURL.authorizeWithURL.url);
    XCTAssertEqualObjects(missingReturnURL.authorizeWithURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(missingReturnURL.authorizeWithURL.returnURL);

    STPPaymentIntentSourceAction *badReturnURL = decode(@{
                                                          @"type": @"authorize_with_url",
                                                          @"authorize_with_url": @{
                                                                  @"url": @"https://stripe.com/",
                                                                  @"return_url": @"not a url"
                                                                  }
                                                          });
    XCTAssertNotNil(badReturnURL);
    XCTAssertEqual(badReturnURL.type, STPPaymentIntentSourceActionTypeAuthorizeWithURL,
                   @"invalid return_url won't prevent it from decoding");
    XCTAssertNotNil(badReturnURL.authorizeWithURL.url);
    XCTAssertEqualObjects(badReturnURL.authorizeWithURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNil(badReturnURL.authorizeWithURL.returnURL);


    STPPaymentIntentSourceAction *complete = decode(@{
                                                              @"type": @"authorize_with_url",
                                                              @"authorize_with_url": @{
                                                                      @"url": @"https://stripe.com/",
                                                                      @"return_url": @"my-app://payment-complete"
                                                                      }
                                                              });
    XCTAssertNotNil(complete);
    XCTAssertEqual(complete.type, STPPaymentIntentSourceActionTypeAuthorizeWithURL);
    XCTAssertNotNil(complete.authorizeWithURL.url);
    XCTAssertEqualObjects(complete.authorizeWithURL.url,
                          [NSURL URLWithString:@"https://stripe.com/"]);
    XCTAssertNotNil(complete.authorizeWithURL.returnURL);
    XCTAssertEqualObjects(complete.authorizeWithURL.returnURL,
                          [NSURL URLWithString:@"my-app://payment-complete"]);
}

@end
