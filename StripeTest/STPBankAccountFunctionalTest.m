//
//  STPBankAccountFunctionalTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

#import <XCTest/XCTest.h>
#import "Stripe.h"
#import "STPBankAccount.h"

@interface STPBankAccountFunctionalTest : XCTestCase

@end

@implementation STPBankAccountFunctionalTest

- (void)testCreateAndRetreiveBankAccountToken {
    [Stripe setDefaultPublishableKey:@"pk_YT1CEhhujd0bklb2KGQZiaL3iTzj3"];
    
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";
    
    __block BOOL done = NO;
    [Stripe createTokenWithBankAccount:bankAccount completion:^(STPToken *token, NSError *error) {
        XCTAssertNil(error, @"error should be nil %@", error.localizedDescription);
        XCTAssertNotNil(token, @"token should not be nil");
        
        XCTAssertNotNil(token.tokenId);
        XCTAssertNotNil(token.bankAccount.bankAccountId);
        XCTAssertEqualObjects(@"STRIPE TEST BANK", token.bankAccount.bankName);
        XCTAssertEqualObjects(@"6789", token.bankAccount.last4);
        
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
    
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    bankAccount.routingNumber = @"110000000";
    bankAccount.country = @"US";
    
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
