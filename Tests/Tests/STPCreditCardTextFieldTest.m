//
//  STPCreditCardTextFieldTest.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

@import XCTest;

#import "STPPaymentTextField.h"

@interface STPCreditCardTextFieldTest : XCTestCase
@end

@implementation STPCreditCardTextFieldTest

- (void)testPaymentTextFieldDelegateBehavesProperly {
    id<STPPaymentTextFieldDelegate> delegate = (id<STPPaymentTextFieldDelegate>)[NSObject new];
    STPPaymentTextField *textField = [STPPaymentTextField new];
    textField.delegate = delegate;
    XCTAssertEqual(textField.delegate, delegate);
}

@end
