//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

@import XCTest;

#import "STPCard.h"
#import "STPFixtures.h"
#import "STPToken.h"

@interface STPTokenTest : XCTestCase
@end

@implementation STPTokenTest

- (void)testCreatingTokenWithAttributeDictionarySetsAttributes {
    STPToken *token = [STPFixtures cardToken];
    XCTAssertEqualObjects([token tokenId], @"id_for_token", @"Generated token has the correct id");
    XCTAssertEqual([token livemode], NO, @"Generated token has the correct livemode");

    XCTAssertEqualWithAccuracy([[token created] timeIntervalSince1970], 1353025450.0, 1.0, @"Generated token has the correct created time");
}

- (void)testCreatingTokenSetsAdditionalResponseFields {
    STPToken *origToken = [STPFixtures cardToken];
    NSMutableDictionary *tokenResponse = [[origToken allResponseFields] mutableCopy];
    tokenResponse[@"foo"] = @"bar";
    STPToken *token = [STPToken decodedObjectFromAPIResponse:tokenResponse];
    NSDictionary *allResponseFields = token.allResponseFields;
    XCTAssertEqualObjects(allResponseFields[@"foo"], @"bar");
    XCTAssertEqualObjects(allResponseFields[@"livemode"], @NO);
    XCTAssertNil(allResponseFields[@"baz"]);
}

@end
