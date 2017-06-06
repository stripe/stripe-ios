//
//  STPCreditCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "Stripe.h"
#import "STPPaymentCardTextFieldViewModel.h"

@interface STPPaymentCardTextFieldViewModelTest : XCTestCase
@property(nonatomic)STPPaymentCardTextFieldViewModel *viewModel;
@end

@implementation STPPaymentCardTextFieldViewModelTest

- (void)setUp {
    [super setUp];
    _viewModel = [STPPaymentCardTextFieldViewModel new];
}

- (void)testCardNumber {
    NSArray *tests = @[
                       @[@"", @""],
                       @[@"4242", @"4242"],
                       @[@"4242424242424242", @"4242424242424242"],
                       @[@"4242 4242 4242 4242", @"4242424242424242"],
                       @[@"4242xxx4242", @"42424242"],
                       @[@"12345678901234567890", @"1234567890123456"],
                       ];
    for (NSArray *test in tests) {
        self.viewModel.cardNumber = test[0];
        XCTAssertEqualObjects(self.viewModel.cardNumber, test[1]);
    }
}

- (void)testRawExpiration {
    NSArray *tests = @[
                       @[@"", @"", @"", @"", @(STPCardValidationStateIncomplete)],
                       @[@"12/23", @"12/23", @"12", @"23", @(STPCardValidationStateValid)],
                       @[@"1223", @"12/23", @"12", @"23", @(STPCardValidationStateValid)],
                       @[@"1", @"1", @"1", @"", @(STPCardValidationStateIncomplete)],
                       @[@"2", @"02/", @"02", @"", @(STPCardValidationStateIncomplete)],
                       @[@"12", @"12/", @"12", @"", @(STPCardValidationStateIncomplete)],
                       @[@"12/2", @"12/2", @"12", @"2", @(STPCardValidationStateIncomplete)],
                       @[@"99/23", @"99", @"99", @"23", @(STPCardValidationStateInvalid)],
                       @[@"10/12", @"10/12", @"10", @"12", @(STPCardValidationStateInvalid)],
                       @[@"12*23", @"12/23", @"12", @"23", @(STPCardValidationStateValid)],
                       @[@"12/*", @"12/", @"12", @"", @(STPCardValidationStateIncomplete)],
                       @[@"*", @"", @"", @"", @(STPCardValidationStateIncomplete)],
                       ];
    for (NSArray *test in tests) {
        self.viewModel.rawExpiration = test[0];
        XCTAssertEqualObjects(self.viewModel.rawExpiration, test[1]);
        XCTAssertEqualObjects(self.viewModel.expirationMonth, test[2]);
        XCTAssertEqualObjects(self.viewModel.expirationYear, test[3]);
        XCTAssertEqualObjects(@([self.viewModel validationStateForField:STPCardFieldTypeExpiration]), test[4]);
    }
}

- (void)testCVC {
    NSArray *tests = @[
                       @[@"1", @"1"],
                       @[@"1234", @"1234"],
                       @[@"12345", @"1234"],
                       @[@"1x", @"1"],
                       ];
    for (NSArray *test in tests) {
        self.viewModel.cvc = test[0];
        XCTAssertEqualObjects(self.viewModel.cvc, test[1]);
    }
}

- (void)testValidity {
    self.viewModel.cardNumber = @"4242424242424242";
    self.viewModel.rawExpiration = @"12/24";
    self.viewModel.cvc = @"123";
    XCTAssertTrue([self.viewModel isValid]);
    
    self.viewModel.cvc = @"12";
    XCTAssertFalse([self.viewModel isValid]);
}

@end
