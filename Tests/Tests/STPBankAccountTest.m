//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@import XCTest;

#import "STPFormEncoder.h"
#import "STPBankAccount.h"

@interface STPBankAccountTest : XCTestCase
@property (nonatomic) STPBankAccountParams *bankAccount;
@end

@implementation STPBankAccountTest

- (void)setUp {
    _bankAccount = [[STPBankAccount alloc] init];
}

- (NSDictionary *)completeAttributeDictionary {
    return @{
        @"id": @"something",
        @"last4": @"6789",
        @"bank_name": @"STRIPE TEST BANK",
        @"country": @"US",
        @"fingerprint": @"something",
        @"currency": @"usd",
        @"status": @"new",
    };
}

- (void)testInitializingBankAccountWithAttributeDictionary {
    NSMutableDictionary *apiResponse = [[self completeAttributeDictionary] mutableCopy];
    apiResponse[@"foo"] = @"bar";
    STPBankAccount *bankAccountWithAttributes = [STPBankAccount decodedObjectFromAPIResponse:apiResponse];

    XCTAssertEqualObjects([bankAccountWithAttributes bankAccountId], @"something", @"bankAccountId is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes last4], @"6789", @"last4 is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes bankName], @"STRIPE TEST BANK", @"bankName is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes country], @"US", @"country is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes fingerprint], @"something", @"fingerprint is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes currency], @"usd", @"currency is set correctly");
    XCTAssertEqual(bankAccountWithAttributes.status, STPBankAccountStatusNew);
    
    NSDictionary *allResponseFields = bankAccountWithAttributes.allResponseFields;
    XCTAssertEqual(allResponseFields[@"foo"], @"bar");
    XCTAssertEqual(allResponseFields[@"last4"], @"6789");
    XCTAssertNil(allResponseFields[@"baz"]);
}

#pragma mark - Last4 Tests

- (void)testLast4ReturnsAccountNumberLast4WhenNotSet {
    self.bankAccount.accountNumber = @"000123456789";
    XCTAssertEqualObjects(self.bankAccount.last4, @"6789", @"last4 correctly returns the last 4 digits of the bank account number");
}

- (void)testLast4ReturnsNullWhenNoAccountNumberSet {
    XCTAssertEqualObjects(nil, self.bankAccount.last4, @"last4 returns nil when nothing is set");
}

- (void)testLast4ReturnsNullWhenAccountNumberIsLessThanLength4 {
    self.bankAccount.accountNumber = @"123";
    XCTAssertEqualObjects(nil, self.bankAccount.last4, @"last4 returns nil when number length is < 4");
}

#pragma mark - Equality Tests

- (void)testBankAccountEquals {
    STPBankAccount *bankAccount1 = [STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    STPBankAccount *bankAccount2 = [STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]];

    XCTAssertEqualObjects(bankAccount1, bankAccount1, @"bank account should equal itself");
    XCTAssertEqualObjects(bankAccount1, bankAccount2, @"bank account with equal data should be equal");
}

@end
