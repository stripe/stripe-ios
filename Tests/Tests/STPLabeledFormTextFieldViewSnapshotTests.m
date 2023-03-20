//
//  STPLabeledFormTextFieldViewSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>


#import "STPTestUtils.h"



@interface STPLabeledFormTextFieldViewSnapshotTests : FBSnapshotTestCase

@end

@implementation STPLabeledFormTextFieldViewSnapshotTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)testAppearance {
    STPFormTextField *formTextField = [[STPFormTextField alloc] init];
    formTextField.placeholder = @"A placeholder";
    formTextField.placeholderColor = [UIColor lightGrayColor];
    STPLabeledFormTextFieldView *labeledFormField = [[STPLabeledFormTextFieldView alloc] initWithFormLabel:@"Test Label" textField:formTextField];
    labeledFormField.formBackgroundColor = [UIColor whiteColor];
    labeledFormField.frame = CGRectMake(0.f, 0.f, 320.f, 44.f);
    STPSnapshotVerifyView(labeledFormField, @"STPLabeledFormTextFieldView.defaultAppearance");
}

@end
