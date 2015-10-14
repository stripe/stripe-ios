//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

@import XCTest;

#import "STPToken.h"
#import "STPCard.h"

@interface STPTokenTest : XCTestCase
@end

@implementation STPTokenTest
- (void)testCreatingTokenWithAttributeDictionarySetsAttributes {
    NSDictionary *cardDict = @{
        @"id": @"card_123",
        @"exp_month": @"12",
        @"exp_year": @"2013",
        @"name": @"Smerlock Smolmes",
        @"address_line1": @"221A Baker Street",
        @"address_city": @"New York",
        @"address_state": @"NY",
        @"address_zip": @"12345",
        @"address_country": @"USA",
        @"last4": @"1234",
        @"brand": @"Visa",
        @"fingerprint": @"Fingolfin",
        @"country": @"Japan"
    };

    NSDictionary *tokenDict = @{ @"id": @"id_for_token", @"object": @"token", @"livemode": @NO, @"created": @1353025450.0, @"used": @NO, @"card": cardDict };
    STPToken *token = [STPToken decodedObjectFromAPIResponse:tokenDict];
    XCTAssertEqualObjects([token tokenId], @"id_for_token", @"Generated token has the correct id");
    XCTAssertEqual([token livemode], NO, @"Generated token has the correct livemode");

    XCTAssertEqualWithAccuracy([[token created] timeIntervalSince1970], 1353025450.0, 1.0, @"Generated token has the correct created time");
}
@end
