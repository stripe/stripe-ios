//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

#import "STPToken.h"
#import "STPCard.h"
#import <XCTest/XCTest.h>

@interface STPTokenTest : XCTestCase
@end

@implementation STPTokenTest
- (void)testCreatingTokenWithAttributeDictionarySetsAttributes {
    NSDictionary *cardDict = @{
        @"number": @"4242424242424242",
        @"expMonth": @"12",
        @"expYear": @"2013",
        @"cvc": @"123",
        @"name": @"Smerlock Smolmes",
        @"addressLine1": @"221A Baker Street",
        @"addressCity": @"New York",
        @"addressState": @"NY",
        @"addressZip": @"12345",
        @"addressCountry": @"USA",
        @"object": @"something",
        @"last4": @"1234",
        @"type": @"Smastersmard",
        @"fingerprint": @"Fingolfin",
        @"country": @"Japan"
    };

    NSDictionary *tokenDict = @{ @"id": @"id_for_token", @"object": @"token", @"livemode": @NO, @"created": @1353025450.0, @"used": @NO, @"card": cardDict };
    STPToken *token = [[STPToken alloc] initWithAttributeDictionary:tokenDict];
    XCTAssertEqualObjects([token tokenId], @"id_for_token", @"Generated token has the correct id");
    XCTAssertEqualObjects([token object], @"token", @"Generated token has the correct object type set");
    XCTAssertEqual([token livemode], NO, @"Generated token has the correct livemode");

    XCTAssertEqualWithAccuracy([[token created] timeIntervalSince1970], 1353025450.0, 1.0, @"Generated token has the correct created time");
    XCTAssertEqualObjects([[token card] number], @"4242424242424242", @"Generated token has the correct card");
}
@end
