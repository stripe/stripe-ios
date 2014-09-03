//
//  STPCardFunctionalTest.m
//  Stripe
//
//  Created by Ray Morgan on 7/11/14.
//
//

#import <XCTest/XCTest.h>
#import "Stripe.h"
#import "STPCard.h"

@interface STPCardFunctionalTest : XCTestCase

@end

@implementation STPCardFunctionalTest

- (void)testCreateAndRetreiveCardToken {
    [Stripe setDefaultPublishableKey:@"pk_YT1CEhhujd0bklb2KGQZiaL3iTzj3"];
    STPCard *card = [[STPCard alloc] init];
    
    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;
    
    __block BOOL done = NO;
    [Stripe createTokenWithCard:card completion:^(STPToken *token, NSError *error) {
        XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
        XCTAssertNotNil(token, @"token should not be nil");
        
        XCTAssertNotNil(token.tokenId);
        XCTAssertEqual(6, token.card.expMonth);
        XCTAssertEqual(2018, token.card.expYear);
        XCTAssertEqualObjects(@"4242", token.card.last4);
        
        [Stripe requestTokenWithID:token.tokenId completion:^(STPToken *token2, NSError *error) {
            XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
            XCTAssertNotNil(token2, @"token should not be nil");
            
            XCTAssertEqualObjects(token, token2, @"expected tokens to ==");
            done = YES;
        }];
    }];
    
    while (!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

- (void)testInvalidKey {
    STPCard *card = [[STPCard alloc] init];

    card.number = @"4242 4242 4242 4242";
    card.expMonth = 6;
    card.expYear = 2018;

    __block BOOL done = NO;
    [Stripe createTokenWithCard:card publishableKey:@"not_a_valid_key_asdf" operationQueue:[NSOperationQueue mainQueue] completion:^(STPToken *token, NSError *error) {
        done = YES;
        XCTAssertNotNil(error, @"error should not be nil");
        XCTAssert([error.localizedDescription rangeOfString:@"asdf"].location != NSNotFound,
                  @"error should contain last 4 of key");
    }];
    while (!done) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

@end
