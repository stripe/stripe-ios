//
//  STPCardValidatorTest.m
//  Stripe
//
//  Created by Jack Flintermann on 7/24/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import UIKit;
@import XCTest;

#import "STPCardValidationState.h"
#import "STPCardValidator.h"

@interface STPCardValidator (Testing)

+ (STPCardValidationState)validationStateForExpirationYear:(NSString *)expirationYear
                                                   inMonth:(NSString *)expirationMonth
                                             inCurrentYear:(NSInteger)currentYear
                                              currentMonth:(NSInteger)currentMonth;

+ (STPCardValidationState)validationStateForCard:(STPCardParams *)card
                                   inCurrentYear:(NSInteger)currentYear
                                    currentMonth:(NSInteger)currentMonth;

@end

@interface STPCardValidatorTest : XCTestCase
@end

@implementation STPCardValidatorTest

+ (NSArray *)cardData {
    return @[
             @[@(STPCardBrandVisa), @"4242424242424242", @(STPCardValidationStateValid)],
             @[@(STPCardBrandVisa), @"4242424242422", @(STPCardValidationStateIncomplete)],
             @[@(STPCardBrandVisa), @"4012888888881881", @(STPCardValidationStateValid)],
             @[@(STPCardBrandVisa), @"4000056655665556", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5555555555554444", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5200828282828210", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"5105105105105100", @(STPCardValidationStateValid)],
             @[@(STPCardBrandMasterCard), @"2223000010089800", @(STPCardValidationStateValid)],
             @[@(STPCardBrandAmex), @"378282246310005", @(STPCardValidationStateValid)],
             @[@(STPCardBrandAmex), @"371449635398431", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDiscover), @"6011111111111117", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDiscover), @"6011000990139424", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDinersClub), @"36227206271667", @(STPCardValidationStateValid)],
             @[@(STPCardBrandDinersClub), @"3056930009020004", @(STPCardValidationStateValid)],
             @[@(STPCardBrandJCB), @"3530111333300000", @(STPCardValidationStateValid)],
             @[@(STPCardBrandJCB), @"3566002020360505", @(STPCardValidationStateValid)],
             @[@(STPCardBrandUnknown), @"1234567812345678", @(STPCardValidationStateInvalid)],
             ];
}

- (void)testNumberSanitization {
    NSArray *tests = @[
                       @[@"4242424242424242", @"4242424242424242"],
                       @[@"XXXXXX", @""],
                       @[@"424242424242424X", @"424242424242424"],
                       @[@"X4242", @"4242"],
                       @[@"4242 4242 4242 4242", @"4242424242424242"]
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects([STPCardValidator sanitizedNumericStringForString:test[0]], test[1]);
    }
}

- (void)testNumberValidation {
    NSMutableArray *tests = [@[] mutableCopy];
    
    for (NSArray *card in [self.class cardData]) {
        [tests addObject:@[card[2], card[1]]];
    }
    
    [tests addObject:@[@(STPCardValidationStateValid), @"4242 4242 4242 4242"]];
    [tests addObject:@[@(STPCardValidationStateValid), @"4136000000008"]];

    NSArray *badCardNumbers = @[
                                @"0000000000000000",
                                @"9999999999999995",
                                @"1",
                                @"1234123412341234",
                                @"xxx",
                                @"9999999999999999999999",
                                @"42424242424242424242",
                                @"4242-4242-4242-4242",
                                ];
    
    for (NSString *card in badCardNumbers) {
        [tests addObject:@[@(STPCardValidationStateInvalid), card]];
    }
    
    NSArray *possibleCardNumbers = @[
                                     @"4242",
                                     @"5",
                                     @"3",
                                     @"",
                                     @"    ",
                                     @"6011",
                                     @"4012888888881"
                                     ];

    for (NSString *card in possibleCardNumbers) {
        [tests addObject:@[@(STPCardValidationStateIncomplete), card]];
    }
    
    for (NSArray *test in tests) {
        NSString *card = test[1];
        NSNumber *validationState = @([STPCardValidator validationStateForNumber:card validatingCardBrand:YES]);
        NSNumber *expected = test[0];
        if (![validationState isEqual:expected]) {
            XCTFail(@"Expected %@, got %@ for number %@", expected, validationState, card);
        }
    }
    
    XCTAssertEqual(STPCardValidationStateIncomplete, [STPCardValidator validationStateForNumber:@"1" validatingCardBrand:NO]);
    XCTAssertEqual(STPCardValidationStateIncomplete, [STPCardValidator validationStateForNumber:@"0000000000000000" validatingCardBrand:NO]);
    XCTAssertEqual(STPCardValidationStateIncomplete, [STPCardValidator validationStateForNumber:@"9999999999999995" validatingCardBrand:NO]);
    XCTAssertEqual(STPCardValidationStateValid, [STPCardValidator validationStateForNumber:@"0000000000000000000" validatingCardBrand:NO]);
    XCTAssertEqual(STPCardValidationStateValid, [STPCardValidator validationStateForNumber:@"9999999999999999998" validatingCardBrand:NO]);
    XCTAssertEqual(STPCardValidationStateIncomplete, [STPCardValidator validationStateForNumber:@"4242424242424" validatingCardBrand:YES]);
    XCTAssertEqual(STPCardValidationStateIncomplete, [STPCardValidator validationStateForNumber:nil validatingCardBrand:YES]);
}

- (void)testBrand {
    for (NSArray *test in [self.class cardData]) {
        XCTAssertEqualObjects(@([STPCardValidator brandForNumber:test[1]]), test[0]);
    }
}

- (void)testLengthsForCardBrand {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @[@13, @16]],
                       @[@(STPCardBrandMasterCard), @[@16]],
                       @[@(STPCardBrandAmex), @[@15]],
                       @[@(STPCardBrandDiscover), @[@16]],
                       @[@(STPCardBrandDinersClub), @[@14, @16]],
                       @[@(STPCardBrandJCB), @[@16]],
                       @[@(STPCardBrandUnionPay), @[@16]],
                       @[@(STPCardBrandUnknown), @[@19]],
                       ];
    for (NSArray *test in tests) {
        NSSet *lengths = [STPCardValidator lengthsForCardBrand:[test[0] integerValue]];
        NSSet *expected = [NSSet setWithArray:test[1]];
        if (![lengths isEqualToSet:expected]) {
            XCTFail(@"Invalid lengths for brand %@: expected %@, got %@", test[0], expected, lengths);
        }
    }
}

- (void)testFragmentLength {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @4],
                       @[@(STPCardBrandMasterCard), @4],
                       @[@(STPCardBrandAmex), @5],
                       @[@(STPCardBrandDiscover), @4],
                       @[@(STPCardBrandDinersClub), @4],
                       @[@(STPCardBrandJCB), @4],
                       @[@(STPCardBrandUnionPay), @4],
                       @[@(STPCardBrandUnknown), @4],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator fragmentLengthForCardBrand:[test[0] integerValue]]), test[1]);
    }
}

- (void)testMonthValidation {
    NSArray *tests = @[
                       @[@"", @(STPCardValidationStateIncomplete)],
                       @[@"0", @(STPCardValidationStateIncomplete)],
                       @[@"1", @(STPCardValidationStateIncomplete)],
                       @[@"2", @(STPCardValidationStateValid)],
                       @[@"9", @(STPCardValidationStateValid)],
                       @[@"10", @(STPCardValidationStateValid)],
                       @[@"12", @(STPCardValidationStateValid)],
                       @[@"13", @(STPCardValidationStateInvalid)],
                       @[@"11a", @(STPCardValidationStateInvalid)],
                       @[@"x", @(STPCardValidationStateInvalid)],
                       @[@"100", @(STPCardValidationStateInvalid)],
                       @[@"00", @(STPCardValidationStateInvalid)],
                       @[@"13", @(STPCardValidationStateInvalid)],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator validationStateForExpirationMonth:test[0]]), test[1]);
    }
}

- (void)testYearValidation {
    NSArray *tests = @[
                       @[@"12", @"15", @(STPCardValidationStateValid)],
                       @[@"8", @"15", @(STPCardValidationStateValid)],
                       @[@"9", @"15", @(STPCardValidationStateValid)],
                       @[@"11", @"16", @(STPCardValidationStateValid)],
                       @[@"11", @"99", @(STPCardValidationStateValid)],
                       @[@"01", @"99", @(STPCardValidationStateValid)],
                       @[@"1", @"99", @(STPCardValidationStateValid)],
                       @[@"00", @"99", @(STPCardValidationStateInvalid)],
                       @[@"12", @"14", @(STPCardValidationStateInvalid)],
                       @[@"7", @"15", @(STPCardValidationStateInvalid)],
                       @[@"12", @"00", @(STPCardValidationStateInvalid)],
                       @[@"13", @"16", @(STPCardValidationStateInvalid)],
                       @[@"12", @"2", @(STPCardValidationStateIncomplete)],
                       @[@"12", @"1", @(STPCardValidationStateIncomplete)],
                       @[@"12", @"0", @(STPCardValidationStateIncomplete)],
                       ];
    
    for (NSArray *test in tests) {
        STPCardValidationState state = [STPCardValidator validationStateForExpirationYear:test[1] inMonth:test[0] inCurrentYear:15 currentMonth:8];
        XCTAssertEqualObjects(@(state), test[2]);
    }
}

- (void)testCVCLength {
    NSArray *tests = @[
                       @[@(STPCardBrandVisa), @3],
                       @[@(STPCardBrandMasterCard), @3],
                       @[@(STPCardBrandAmex), @4],
                       @[@(STPCardBrandDiscover), @3],
                       @[@(STPCardBrandDinersClub), @3],
                       @[@(STPCardBrandJCB), @3],
                       @[@(STPCardBrandUnionPay), @3],
                       @[@(STPCardBrandUnknown), @4],
                       ];
    for (NSArray *test in tests) {
        XCTAssertEqualObjects(@([STPCardValidator maxCVCLengthForCardBrand:[test[0] integerValue]]), test[1]);
    }
}

- (void)testCVCValidation {
    NSArray *tests = @[
                       @[@"x", @(STPCardBrandVisa), @(STPCardValidationStateInvalid)],
                       @[@"", @(STPCardBrandVisa), @(STPCardValidationStateIncomplete)],
                       @[@"1", @(STPCardBrandVisa), @(STPCardValidationStateIncomplete)],
                       @[@"12", @(STPCardBrandVisa), @(STPCardValidationStateIncomplete)],
                       @[@"1x3", @(STPCardBrandVisa), @(STPCardValidationStateInvalid)],
                       @[@"123", @(STPCardBrandVisa), @(STPCardValidationStateValid)],
                       @[@"123", @(STPCardBrandAmex), @(STPCardValidationStateValid)],
                       @[@"123", @(STPCardBrandUnknown), @(STPCardValidationStateValid)],
                       @[@"1234", @(STPCardBrandVisa), @(STPCardValidationStateInvalid)],
                       @[@"1234", @(STPCardBrandAmex), @(STPCardValidationStateValid)],
                       @[@"12345", @(STPCardBrandAmex), @(STPCardValidationStateInvalid)],
                       ];
    
    for (NSArray *test in tests) {
        STPCardValidationState state = [STPCardValidator validationStateForCVC:test[0] cardBrand:[test[1] integerValue]];
        XCTAssertEqualObjects(@(state), test[2]);
    }
}

- (void)testCardValidation {
    NSArray *tests = @[
                       @[@"4242424242424242", @(12), @(15), @"123", @(STPCardValidationStateValid)],
                       @[@"4242424242424242", @(12), @(15), @"x", @(STPCardValidationStateInvalid)],
                       @[@"4242424242424242", @(12), @(15), @"1", @(STPCardValidationStateIncomplete)],
                       @[@"4242424242424242", @(12), @(14), @"123", @(STPCardValidationStateInvalid)],
                       @[@"4242424242424242", @(21), @(15), @"123", @(STPCardValidationStateInvalid)],
                       @[@"42424242", @(12), @(15), @"123", @(STPCardValidationStateIncomplete)],
                       @[@"378282246310005", @(12), @(15), @"1234", @(STPCardValidationStateValid)],
                       @[@"378282246310005", @(12), @(15), @"123", @(STPCardValidationStateValid)],
                       @[@"378282246310005", @(12), @(15), @"12345", @(STPCardValidationStateInvalid)],
                       @[@"1234567812345678", @(12), @(15), @"12345", @(STPCardValidationStateInvalid)],
                       ];
    for (NSArray *test in tests) {
        STPCardParams *card = [[STPCardParams alloc] init];
        card.number = test[0];
        card.expMonth = [test[1] integerValue];
        card.expYear = [test[2] integerValue];
        card.cvc = test[3];
        STPCardValidationState state = [STPCardValidator validationStateForCard:card
                                        inCurrentYear:15 currentMonth:8];
        if (![@(state) isEqualToNumber:test[4]]) {
            XCTFail(@"Wrong validation state for %@. Expected %@, got %@", card.number, test[4], @(state));
        }
    }
}


@end
