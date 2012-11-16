//
//  STPTokenTest.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/9/12.
//
//

#import "STPTokenTest.h"
#import "STPToken.h"
#import "STPCard.h"

@implementation STPTokenTest
- (void)testCreatingTokenWithAttributeDictionarySetsAttributes
{
    NSDictionary *cardDict = [NSDictionary dictionaryWithObjectsAndKeys:@"4242424242424242", @"number", @"12", @"expMonth", @"2013", @"expYear", @"123", @"cvc", @"Smerlock Smolmes", @"name", @"221A Baker Street", @"addressLine1", @"New York", @"addressCity", @"NY", @"addressState", @"12345", @"addressZip", @"USA", @"addressCountry", @"something", @"object", @"1234", @"last4", @"Smastersmard", @"type", @"Fingolfin", @"fingerprint", @"Japan", @"country", nil];
    
    NSDictionary *tokenDict = [NSDictionary dictionaryWithObjectsAndKeys:@"id_for_token", @"id", @"token", @"object", [NSNumber numberWithBool:NO], @"livemode", [NSNumber numberWithDouble:1353025450], @"created", [NSNumber numberWithBool:NO], @"used", cardDict, @"card", nil];
    STPToken *token = [[STPToken alloc] initWithAttributeDictionary:tokenDict];
    STAssertEqualObjects([token tokenId], @"id_for_token", @"Generated token has the correct id");
    STAssertEqualObjects([token object], @"token", @"Generated token has the correct object type set");
    STAssertEquals([token livemode], NO, @"Generated token has the correct livemode");
    
    STAssertEquals([[token created] timeIntervalSince1970], 1353025450.0, @"Generated token has the correct created time");
    STAssertEqualObjects([[token card] number], @"4242424242424242", @"Generated token has the correct card");
}
@end
