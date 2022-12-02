//
//  STPBankAccountTest.m
//  Stripe
//
//  Created by Charles Scalesse on 10/2/14.
//
//

@import XCTest;



#import "STPTestUtils.h"

@interface STPBankAccount ()

+ (STPBankAccountStatus)statusFromString:(NSString *)string;
+ (NSString *)stringFromStatus:(STPBankAccountStatus)status;

- (void)setLast4:(NSString *)last4;

@end

@interface STPBankAccountTest : XCTestCase

@end

@implementation STPBankAccountTest

#pragma mark - STPBankAccountStatus Tests

- (void)testStatusFromString {
    XCTAssertEqual([STPBankAccount statusFromString:@"new"], STPBankAccountStatusNew);
    XCTAssertEqual([STPBankAccount statusFromString:@"NEW"], STPBankAccountStatusNew);

    XCTAssertEqual([STPBankAccount statusFromString:@"validated"], STPBankAccountStatusValidated);
    XCTAssertEqual([STPBankAccount statusFromString:@"VALIDATED"], STPBankAccountStatusValidated);

    XCTAssertEqual([STPBankAccount statusFromString:@"verified"], STPBankAccountStatusVerified);
    XCTAssertEqual([STPBankAccount statusFromString:@"VERIFIED"], STPBankAccountStatusVerified);

    XCTAssertEqual([STPBankAccount statusFromString:@"verification_failed"], STPBankAccountStatusVerificationFailed);
    XCTAssertEqual([STPBankAccount statusFromString:@"VERIFICATION_FAILED"], STPBankAccountStatusVerificationFailed);

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
                                    @(STPBankAccountStatusVerificationFailed),
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
            case STPBankAccountStatusVerificationFailed:
                XCTAssertEqualObjects(string, @"verification_failed");
                break;
            case STPBankAccountStatusErrored:
                XCTAssertEqualObjects(string, @"errored");
                break;
        }
    }
}

#pragma mark - Equality Tests

- (void)testBankAccountEquals {
    STPBankAccount *bankAccount1 = [STPBankAccount decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BankAccount"]];
    STPBankAccount *bankAccount2 = [STPBankAccount decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BankAccount"]];

    XCTAssertNotEqual(bankAccount1, bankAccount2);

    XCTAssertEqualObjects(bankAccount1, bankAccount1);
    XCTAssertEqualObjects(bankAccount1, bankAccount2);

    XCTAssertEqual(bankAccount1.hash, bankAccount1.hash);
    XCTAssertEqual(bankAccount1.hash, bankAccount2.hash);
}

#pragma mark - Description Tests

- (void)testDescription {
    STPBankAccount *bankAccount = [STPBankAccount decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BankAccount"]];
    XCTAssert(bankAccount.description);
}

#pragma mark - STPAPIResponseDecodable Tests

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
        NSMutableDictionary *response = [[STPTestUtils jsonNamed:@"BankAccount"] mutableCopy];
        [response removeObjectForKey:field];

        XCTAssertNil([STPBankAccount decodedObjectFromAPIResponse:response]);
    }

    XCTAssert([STPBankAccount decodedObjectFromAPIResponse:[STPTestUtils jsonNamed:@"BankAccount"]]);
}

- (void)testDecodedObjectFromAPIResponseMapping {
    NSDictionary *response = [STPTestUtils jsonNamed:@"BankAccount"];
    STPBankAccount *bankAccount = [STPBankAccount decodedObjectFromAPIResponse:response];

    XCTAssertEqualObjects(bankAccount.stripeID, @"ba_1AZmya2eZvKYlo2CQzt7Fwnz");
    XCTAssertEqualObjects(bankAccount.accountHolderName, @"Jane Austen");
    XCTAssertEqual(bankAccount.accountHolderType, STPBankAccountHolderTypeIndividual);
    XCTAssertEqualObjects(bankAccount.bankName, @"STRIPE TEST BANK");
    XCTAssertEqualObjects(bankAccount.country, @"US");
    XCTAssertEqualObjects(bankAccount.currency, @"usd");
    XCTAssertEqualObjects(bankAccount.fingerprint, @"1JWtPxqbdX5Gamtc");
    XCTAssertEqualObjects(bankAccount.last4, @"6789");
    XCTAssertEqualObjects(bankAccount.routingNumber, @"110000000");
    XCTAssertEqual(bankAccount.status, STPBankAccountStatusNew);

    XCTAssertNotEqual(bankAccount.allResponseFields, response);
    XCTAssertEqualObjects(bankAccount.allResponseFields, response);
}

@end
