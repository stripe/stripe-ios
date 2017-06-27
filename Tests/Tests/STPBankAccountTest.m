//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@import XCTest;

#import "STPBankAccount.h"
#import "STPBankAccount+Private.h"

#import "STPFormEncoder.h"

@interface STPBankAccountTest : XCTestCase

@end

@implementation STPBankAccountTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - STPBankAccountStatus Tests

- (void)testStatusFromString {
    XCTAssertEqual([STPBankAccount statusFromString:@"new"], STPBankAccountStatusNew);
    XCTAssertEqual([STPBankAccount statusFromString:@"NEW"], STPBankAccountStatusNew);

    XCTAssertEqual([STPBankAccount statusFromString:@"validated"], STPBankAccountStatusValidated);
    XCTAssertEqual([STPBankAccount statusFromString:@"VALIDATED"], STPBankAccountStatusValidated);

    XCTAssertEqual([STPBankAccount statusFromString:@"verified"], STPBankAccountStatusVerified);
    XCTAssertEqual([STPBankAccount statusFromString:@"VERIFIED"], STPBankAccountStatusVerified);

    XCTAssertEqual([STPBankAccount statusFromString:@"errored"], STPBankAccountStatusErrored);
    XCTAssertEqual([STPBankAccount statusFromString:@"ERRORED"], STPBankAccountStatusErrored);

    XCTAssertEqual([STPBankAccount statusFromString:@"garbage"], STPBankAccountStatusNew);
    XCTAssertEqual([STPBankAccount statusFromString:@"GARBAGE"], STPBankAccountStatusNew);
}

- (void)testStringFromStatus {
    NSArray<NSNumber *> *values = @[
                                    @(STPBankAccountStatusNew),
                                    @(STPBankAccountStatusValidated),
                                    @(STPBankAccountStatusVerified),
                                    @(STPBankAccountStatusErrored)
                                    ];

    for (NSNumber *statusNumber in values) {
        STPBankAccountStatus status = (STPBankAccountStatus)[statusNumber integerValue];
        NSString *string = [STPBankAccount stringFromStatus:status];

        switch (status) {
            case STPBankAccountStatusNew:
                XCTAssertEqualObjects(string, @"new");
                break;
            case STPBankAccountStatusValidated:
                XCTAssertEqualObjects(string, @"validated");
                break;
            case STPBankAccountStatusVerified:
                XCTAssertEqualObjects(string, @"verified");
                break;
            case STPBankAccountStatusErrored:
                XCTAssertEqualObjects(string, @"errored");
                break;
        }
    }
}

#pragma mark -

- (void)testSetAccountNumber {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    XCTAssertNil(bankAccount.accountNumber);

    bankAccount.accountNumber = @"000123456789";
    XCTAssertEqualObjects(bankAccount.accountNumber, @"000123456789");
}

- (void)testLast4ReturnsAccountNumberLast4WhenNotSet {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"000123456789";
    XCTAssertEqualObjects(bankAccount.last4, @"6789");
}

- (void)testLast4ReturnsNilWhenNoAccountNumberSet {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    XCTAssertNil(bankAccount.last4);
}

- (void)testLast4ReturnsNilWhenAccountNumberIsLessThanLength4 {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = @"123";
    XCTAssertNil(bankAccount.last4);
}

- (void)testLast4ReturnsValueOverAccountNumberDerivation {
    STPBankAccount *bankAccount = [[STPBankAccount alloc] init];
    bankAccount.accountNumber = nil;
    bankAccount.last4 = @"1234";
    XCTAssertEqualObjects(bankAccount.last4, @"1234");
}

#pragma mark - Equality Tests

- (void)testBankAccountEquals {
    STPBankAccount *bankAccount1 = [STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    STPBankAccount *bankAccount2 = [STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]];

    XCTAssertNotEqual(bankAccount1, bankAccount2);

    XCTAssertEqualObjects(bankAccount1, bankAccount1);
    XCTAssertEqualObjects(bankAccount1, bankAccount2);

    XCTAssertEqual(bankAccount1.hash, bankAccount1.hash);
    XCTAssertEqual(bankAccount1.hash, bankAccount2.hash);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPBankAccount *bankAccount = [STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]];
    XCTAssert(bankAccount.description);
}

#pragma mark - STPAPIResponseDecodable Tests

- (NSDictionary *)completeAttributeDictionary {
    // Source: https://stripe.com/docs/api#customer_bank_account_object
    return @{
             @"id": @"ba_1AXvnKEOD54MuFwSotKc6xq0",
             @"object": @"bank_account",
             @"account": @"acct_1AHMhqEOD54MuFwS",
             @"account_holder_name": @"Jane Austen",
             @"account_holder_type": @"individual",
             @"bank_name": @"STRIPE TEST BANK",
             @"country": @"US",
             @"currency": @"usd",
             @"default_for_currency": @(NO),
             @"fingerprint": @"C5fW7AwE3of8bHvV",
             @"last4": @"6789",
             @"metadata": @{},
             @"routing_number": @"110000000",
             @"status": @"new",
             @"customer": @"cus_AtMGi1QH6GlMP4",
             };
}

- (void)testDecodedObjectFromAPIResponseRequiredFields {
    NSArray<NSString *> *requiredFields = @[
                                            @"id",
                                            @"last4",
                                            @"bank_name",
                                            @"country",
                                            @"currency",
                                            @"status",
                                            ];

    for (NSString *field in requiredFields) {
        NSMutableDictionary *response = [[self completeAttributeDictionary] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPBankAccount decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPBankAccount decodedObjectFromAPIResponse:[self completeAttributeDictionary]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [self completeAttributeDictionary];
    STPBankAccount *bankAccount = [STPBankAccount decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(bankAccount.bankAccountId, @"ba_1AXvnKEOD54MuFwSotKc6xq0");
    XCTAssertEqualObjects(bankAccount.accountHolderName, @"Jane Austen");
    XCTAssertEqual(bankAccount.accountHolderType, STPBankAccountHolderTypeIndividual);
    XCTAssertEqualObjects(bankAccount.bankName, @"STRIPE TEST BANK");
    XCTAssertEqualObjects(bankAccount.country, @"US");
    XCTAssertEqualObjects(bankAccount.currency, @"usd");
    XCTAssertEqualObjects(bankAccount.fingerprint, @"C5fW7AwE3of8bHvV");
    XCTAssertEqualObjects(bankAccount.last4, @"6789");
    XCTAssertNil(bankAccount.routingNumber);
    XCTAssertEqual(bankAccount.status, STPBankAccountStatusNew);

    XCTAssertNotEqual(bankAccount.allResponseFields, response);
    XCTAssertEqualObjects(bankAccount.allResponseFields, response);
}

@end
