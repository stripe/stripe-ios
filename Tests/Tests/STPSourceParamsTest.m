//
//  STPSourceParamsTest.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Stripe/Stripe.h>
#import "STPFixtures.h"
#import "STPFormEncoder.h"
#import "STPSource+Private.h"
#import "STPSourceParams+Private.h"

@interface STPSourceParamsTest : XCTestCase

@end

@implementation STPSourceParamsTest

- (void)testCardParamsWithCard {
    STPCardParams *card = [STPFixtures cardParams];

    STPSourceParams *source = [STPSourceParams cardParamsWithCard:card];
    NSDictionary *sourceCard = source.additionalAPIParameters[@"card"];
    XCTAssertEqualObjects(sourceCard[@"number"], card.number);
    XCTAssertEqualObjects(sourceCard[@"cvc"], card.cvc);
    XCTAssertEqualObjects(sourceCard[@"exp_month"], @(card.expMonth));
    XCTAssertEqualObjects(sourceCard[@"exp_year"], @(card.expYear));
    XCTAssertEqualObjects(source.owner[@"name"], card.name);
    NSDictionary *sourceAddress = source.owner[@"address"];
    XCTAssertEqualObjects(sourceAddress[@"line1"], card.addressLine1);
    XCTAssertEqualObjects(sourceAddress[@"line2"], card.addressLine2);
    XCTAssertEqualObjects(sourceAddress[@"city"], card.addressCity);
    XCTAssertEqualObjects(sourceAddress[@"state"], card.addressState);
    XCTAssertEqualObjects(sourceAddress[@"postal_code"], card.addressZip);
    XCTAssertEqualObjects(sourceAddress[@"country"], card.addressCountry);
}

- (NSString *)redirectMerchantNameQueryItemValueFromURLString:(NSString *)urlString {
    NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"redirect_merchant_name"]) {
            return item.value;
        }
    }
    return nil;
}

- (void)testRedirectMerchantNameURL {
    STPSourceParams *sourceParams = [STPSourceParams sofortParamsWithAmount:1000
                                                                  returnURL:@"test://foo?value=baz"
                                                                    country:@"DE"
                                                        statementDescriptor:nil];

    NSDictionary *params = [STPFormEncoder dictionaryForObject:sourceParams];
    // Should be nil because we have no app name in tests
    XCTAssertNil([self redirectMerchantNameQueryItemValueFromURLString:params[@"redirect"][@"return_url"]]);

    sourceParams.redirectMerchantName = @"bar";
    params = [STPFormEncoder dictionaryForObject:sourceParams];
    XCTAssertEqualObjects([self redirectMerchantNameQueryItemValueFromURLString:params[@"redirect"][@"return_url"]], @"bar");

    sourceParams = [STPSourceParams sofortParamsWithAmount:1000
                                                 returnURL:@"test://foo?redirect_merchant_name=Manual%20Custom%20Name"
                                                   country:@"DE"
                                       statementDescriptor:nil];
    sourceParams.redirectMerchantName = @"bar";
    params = [STPFormEncoder dictionaryForObject:sourceParams];
    // Don't override names set by the user directly in the url
    XCTAssertEqualObjects([self redirectMerchantNameQueryItemValueFromURLString:params[@"redirect"][@"return_url"]], @"Manual Custom Name");

}

- (void)testRawTypeString {
    STPSourceParams *sourceParams = [STPSourceParams new];
    // Check defaults to unknown

    XCTAssertEqual(sourceParams.type, STPSourceTypeUnknown);

    // Check changing type sets rawTypeString
    sourceParams.type = STPSourceTypeCard;
    XCTAssertEqualObjects(sourceParams.rawTypeString, [STPSource stringFromType:STPSourceTypeCard]);

    // Check changing to unknown raw string sets type to unknown
    sourceParams.rawTypeString = @"new_source_type";
    XCTAssertEqual(sourceParams.type, STPSourceTypeUnknown);

    // Check once unknown that setting type to unknown doesnt clobber string
    sourceParams.type = STPSourceTypeUnknown;
    XCTAssertEqualObjects(sourceParams.rawTypeString, @"new_source_type");

    // Check setting string to known type sets type correctly
    sourceParams.rawTypeString = [STPSource stringFromType:STPSourceTypeIDEAL];
    XCTAssertEqual(sourceParams.type, STPSourceTypeIDEAL);
}

@end
