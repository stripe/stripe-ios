//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

@import XCTest;



@interface STPTokenTest : XCTestCase
@end

@implementation STPTokenTest

- (NSDictionary *)buildTestTokenResponse {
    NSDictionary *cardDict = @{
                               @"id": @"card_123",
                               @"exp_month": @"12",
                               @"exp_year": @"2013",
                               @"name": @"Smerlock Smolmes",
                               @"address_line1": @"221A Baker Street",
                               @"address_city": @"New York",
                               @"address_state": @"NY",
                               @"address_zip": @"12345",
                               @"address_country": @"US",
                               @"last4": @"1234",
                               @"brand": @"Visa",
                               @"fingerprint": @"Fingolfin",
                               @"country": @"JP",
                               };
    
    NSDictionary *tokenDict = @{ @"id": @"id_for_token", @"object": @"token", @"livemode": @NO, @"created": @1353025450.0, @"used": @NO, @"card": cardDict, @"type": @"card" };
    return tokenDict;
}

- (void)testCreatingTokenWithAttributeDictionarySetsAttributes {
    STPToken *token = [STPToken decodedObjectFromAPIResponse:[self buildTestTokenResponse]];
    XCTAssertEqualObjects([token tokenId], @"id_for_token", @"Generated token has the correct id");
    XCTAssertEqual([token livemode], NO, @"Generated token has the correct livemode");
    XCTAssertEqual([token type], STPTokenTypeCard, @"Generated token has incorrect type");

    XCTAssertEqualWithAccuracy([[token created] timeIntervalSince1970], 1353025450.0, 1.0, @"Generated token has the correct created time");
}

- (void)testCreatingTokenSetsAdditionalResponseFields {
    NSMutableDictionary *tokenResponse = [[self buildTestTokenResponse] mutableCopy];
    tokenResponse[@"foo"] = @"bar";
    STPToken *token = [STPToken decodedObjectFromAPIResponse:tokenResponse];
    NSDictionary *allResponseFields = token.allResponseFields;
    XCTAssertEqualObjects(allResponseFields[@"foo"], @"bar");
    XCTAssertEqualObjects(allResponseFields[@"livemode"], @NO);
    XCTAssertNil(allResponseFields[@"baz"]);
}

@end
