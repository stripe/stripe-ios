//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

#import "STPBankAccount.h"
#import "STPUtils.h"
#import <XCTest/XCTest.h>

@interface STPBankAccountTest : XCTestCase
@property (nonatomic) STPBankAccount *bankAccount;
@end

@implementation STPBankAccountTest

- (void)setUp {
    _bankAccount = [[STPBankAccount alloc] init];
}

#pragma mark - initWithAttributeDictionary: Tests

- (NSDictionary *)completeAttributeDictionary {
    return @{
        @"object": @"bank_account",
        @"id": @"something",
        @"last4": @"6789",
        @"bank_name": @"STRIPE TEST BANK",
        @"country": @"US",
        @"fingerprint": @"something",
        @"currency": @"usd",
        @"validated": @(NO),
        @"disabled": @(NO)
    };
}

- (void)testInitializingBankAccountWithAttributeDictionary {
    STPBankAccount *bankAccountWithAttributes = [[STPBankAccount alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];

    XCTAssertEqualObjects([bankAccountWithAttributes object], @"bank_account", @"object is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes bankAccountId], @"something", @"bankAccountId is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes last4], @"6789", @"last4 is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes bankName], @"STRIPE TEST BANK", @"bankName is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes country], @"US", @"country is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes fingerprint], @"something", @"fingerprint is set correctly");
    XCTAssertEqualObjects([bankAccountWithAttributes currency], @"usd", @"currency is set correctly");
    XCTAssertEqual([bankAccountWithAttributes validated], NO, @"validated is set correctly");
    XCTAssertEqual([bankAccountWithAttributes disabled], NO, @"disabled is set correctly");
}

- (void)testFormEncode {
    NSDictionary *attributes = [self completeAttributeDictionary];
    STPBankAccount *bankAccountWithAttributes = [[STPBankAccount alloc] initWithAttributeDictionary:attributes];

    NSData *encoded = [bankAccountWithAttributes formEncode];
    NSString *formData = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];

    NSArray *parts = [formData componentsSeparatedByString:@"&"];

    NSSet *expectedKeys = [NSSet setWithObjects:@"bank_account[account_number]", @"bank_account[routing_number]", @"bank_account[country]", nil];

    NSArray *values = [attributes allValues];
    NSMutableArray *encodedValues = [NSMutableArray array];
    for (NSString *value in values) {
        NSString *stringValue = nil;
        if ([value isKindOfClass:[NSString class]]) {
            stringValue = value;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            stringValue = [((NSNumber *)value)stringValue];
        }
        if (stringValue) {
            [encodedValues addObject:[STPUtils stringByURLEncoding:stringValue]];
        }
    }

    NSSet *expectedValues = [NSSet setWithArray:encodedValues];

    for (NSString *part in parts) {
        NSArray *subparts = [part componentsSeparatedByString:@"="];
        NSString *key = subparts[0];
        NSString *value = subparts[1];

        XCTAssertTrue([expectedKeys containsObject:key], @"unexpected key %@", key);
        XCTAssertTrue([expectedValues containsObject:value], @"unexpected value %@", value);
    }
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
    STPBankAccount *bankAccount1 = [[STPBankAccount alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];
    STPBankAccount *bankAccount2 = [[STPBankAccount alloc] initWithAttributeDictionary:[self completeAttributeDictionary]];

    XCTAssertEqualObjects(bankAccount1, bankAccount1, @"bank account should equal itself");
    XCTAssertEqualObjects(bankAccount1, bankAccount2, @"bank account with equal data should be equal");

    bankAccount1.accountNumber = @"1234";
    XCTAssertNotEqualObjects(bankAccount1, bankAccount2, @"bank accounts should not match");
}

@end
