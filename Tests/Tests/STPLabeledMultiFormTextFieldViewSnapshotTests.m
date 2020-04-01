//
//  STPLabeledMultiFormTextFieldViewSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "STPLabeledMultiFormTextFieldView.h"

#import "STPFormTextField.h"

@interface STPLabeledMultiFormTextFieldViewSnapshotTests : FBSnapshotTestCase

@end

@implementation STPLabeledMultiFormTextFieldViewSnapshotTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)testAppearance {
    STPFormTextField *formTextField1 = [[STPFormTextField alloc] init];
    formTextField1.placeholder = @"Placeholder 1";
    formTextField1.placeholderColor = [UIColor lightGrayColor];

    STPFormTextField *formTextField2 = [[STPFormTextField alloc] init];
    formTextField2.placeholder = @"Placeholder 2";
    formTextField2.placeholderColor = [UIColor lightGrayColor];

    STPLabeledMultiFormTextFieldView *labeledFormField = [[STPLabeledMultiFormTextFieldView alloc] initWithFormLabel:@"Test Label"
                                                                                                      firstTextField:formTextField1
                                                                                                     secondTextField:formTextField2];
    labeledFormField.formBackgroundColor = [UIColor whiteColor];
    labeledFormField.frame = CGRectMake(0.f, 0.f, 320.f, 62.f);
    FBSnapshotVerifyView(labeledFormField, @"STPLabeledMultiFormTextFieldView.defaultAppearance");
}

@end
