//
//  STPAUBECSDebitFormViewSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 3/13/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "STPAUBECSDebitFormView+Testing.h"

#import "STPFormTextField.h"

@interface STPAUBECSDebitFormViewSnapshotTests : FBSnapshotTestCase

@end

@implementation STPAUBECSDebitFormViewSnapshotTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)testDefaultAppearance {
    STPAUBECSDebitFormView *view = [self _newFormView];
    [self _sizeToFit:view];
    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.defaultAppearance");
}

- (void)testNoDataCustomization {
    STPAUBECSDebitFormView *view = [self _newFormView];

    [self _applyCustomization:view];

    [self _sizeToFit:view];


    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.noDataCustomization");
}

- (void)testWithDataAppearance {
    STPAUBECSDebitFormView *view = [self _newFormView];
    view.nameTextField.text = @"Jenny Rosen";
    view.emailTextField.text = @"jrosen@example.com";
    view.bsbNumberTextField.text = @"111111";
    view.accountNumberTextField.text = @"123456";
    [self _sizeToFit:view];

    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.withDataAppearance");
}

- (void)testWithDataCustomization {
    STPAUBECSDebitFormView *view = [self _newFormView];
    view.nameTextField.text = @"Jenny Rosen";
    view.emailTextField.text = @"jrosen@example.com";
    view.bsbNumberTextField.text = @"111111";
    view.accountNumberTextField.text = @"123456";
    [self _applyCustomization:view];
    [self _sizeToFit:view];

    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.withDataAppearance");
}

- (void)testInvalidBSBAndEmailAppearance {
    STPAUBECSDebitFormView *view = [self _newFormView];
    view.nameTextField.text = @"Jenny Rosen";
    view.emailTextField.text = @"jrosen";
    view.bsbNumberTextField.text = @"666666";
    view.accountNumberTextField.text = @"123456";
    [self _sizeToFit:view];

    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.invalidBSBAndEmailAppearance");
}

- (void)testInvalidBSBAndEmailCustomization {
    STPAUBECSDebitFormView *view = [self _newFormView];
    view.nameTextField.text = @"Jenny Rosen";
    view.emailTextField.text = @"jrosen";
    view.bsbNumberTextField.text = @"666666";
    view.accountNumberTextField.text = @"123456";
    [self _applyCustomization:view];
    [self _sizeToFit:view];

    FBSnapshotVerifyView(view, @"STPAUBECSDebitFormView.invalidBSBAndEmailCustomization");
}


#pragma mark - Helpers

- (STPAUBECSDebitFormView *)_newFormView {
    STPAUBECSDebitFormView *formView = [[STPAUBECSDebitFormView alloc] initWithCompanyName:@"Snapshotter"];
    formView.frame = CGRectMake(0.f, 0.f, 320.f, 600.f);
    return formView;
}

- (void)_applyCustomization:(STPAUBECSDebitFormView *)view {
    view.formFont = [UIFont boldSystemFontOfSize:12.f];
    view.formTextColor = [UIColor blueColor];
    view.formTextErrorColor = [UIColor orangeColor];
    view.formPlaceholderColor = [UIColor blackColor];
    view.formCursorColor = [UIColor redColor];
    view.formBackgroundColor = [UIColor colorWithRed:255.f/255.f green:45.f/255.f blue:85.f/255.f alpha:1.f];
}

- (void)_sizeToFit:(STPAUBECSDebitFormView *)view {
    CGRect adjustedFrame = view.frame;
    adjustedFrame.size.height = [view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    view.frame = adjustedFrame;
}


@end
