//
//  STDSChallengeResponseViewControllerSnapshotTests.m
//  Stripe3DS2DemoUITests
//
//  Created by Andrew Harrison on 3/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import iOSSnapshotTestCaseCore;

#import <XCTest/XCTest.h>

#import "STDSChallengeResponseViewController.h"
#import "STDSChallengeResponseObject+TestObjects.h"
#import "STDSExpandableInformationView.h"
#import "STDSStackView.h"
#import "STDSTextChallengeView.h"

/**
 Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
 @param view The view to snapshot.
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define STPSnapshotVerifyView(view__, identifier__) \
FBSnapshotVerifyViewWithPixelOptions(view__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0.02, 0)

@interface STDSChallengeResponseViewControllerSnapshotTests: FBSnapshotTestCase

@end

@interface STDSChallengeResponseViewController (Testing)

- (nullable id<STDSChallengeResponseSelectionInfo>)whitelistResponse;

@end

@implementation STDSChallengeResponseViewControllerSnapshotTests

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (NSString *)getReferenceImageDirectoryWithDefault:(NSString *)dir {
    NSString *envDir = NSProcessInfo.processInfo.environment[@"SNAPSHOT_RECORD_DIR"];
    return envDir ?: @"/tmp/snapshot-records";
}

- (void)recordIssue:(XCTIssue *)issue {
    if (self.recordMode && [issue.compactDescription containsString:@"record mode"]) {
        return;
    }
    [super recordIssue:issue];
}

- (void)testVerifyTextChallengeDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:NO] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];

    XCTAssertNil([challengeResponseViewController whitelistResponse]);

    STPSnapshotVerifyView(challengeResponseViewController.view, @"TextChallengeResponse");
}

- (void)testWhitelistResponseExists {
    id<STDSChallengeResponse> object = [STDSChallengeResponseObject textChallengeResponseWithWhitelist:YES resendCode:NO];
    
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:object directoryServer:STDSDirectoryServerVisa];
    [challengeResponseViewController view];

    [self waitForChallengeResponseTimer];
    
    XCTAssertNotNil([challengeResponseViewController whitelistResponse]);
}

- (void)testVerifySingleSelectDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject singleSelectChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    STPSnapshotVerifyView(challengeResponseViewController.view, @"SingleSelectResponse");
}

- (void)testVerifyMultiSelectDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject multiSelectChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    STPSnapshotVerifyView(challengeResponseViewController.view, @"MultiSelectResponse");
}

- (void)testVerifyOOBDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject OOBChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    STPSnapshotVerifyView(challengeResponseViewController.view, @"OOBResponse");
}

- (void)testHorizontalStackViewUsesRightToLeftOrder {
    STDSStackView *stackView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisHorizontal];
    stackView.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    stackView.frame = CGRectMake(0, 0, 100, 40);

    UIView *firstView = [UIView new];
    UIView *secondView = [UIView new];
    [stackView addArrangedSubview:firstView];
    [stackView addArrangedSubview:secondView];
    [NSLayoutConstraint activateConstraints:@[
        [firstView.widthAnchor constraintEqualToConstant:40],
        [secondView.widthAnchor constraintEqualToConstant:60],
    ]];

    [stackView layoutIfNeeded];

    XCTAssertGreaterThan(CGRectGetMinX(firstView.frame), CGRectGetMinX(secondView.frame));
}

- (void)testExpandableInformationChevronFlipsForRightToLeftLayout {
    STDSExpandableInformationView *view = [STDSExpandableInformationView new];
    UIImageView *titleImageView = [view valueForKey:@"titleImageView"];

    XCTAssertTrue(titleImageView.image.flipsForRightToLeftLayoutDirection);
}

- (void)testTextFieldEditingRectDoesNotOverlapRightToLeftClearButton {
    STDSTextField *textField = [STDSTextField new];
    textField.frame = CGRectMake(0, 0, 320, 44);
    textField.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    textField.clearButtonMode = UITextFieldViewModeAlways;
    textField.text = @"123456";

    CGRect editingRect = [textField editingRectForBounds:textField.bounds];
    CGRect clearButtonRect = [textField clearButtonRectForBounds:textField.bounds];

    XCTAssertFalse(CGRectIntersectsRect(editingRect, clearButtonRect));
}

- (void)testLoadingAmex {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerAmex];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    STPSnapshotVerifyView(challengeResponseViewController.view, @"LoadingAmex");
}

- (void)testLoadingDiscover {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerDiscover];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    STPSnapshotVerifyView(challengeResponseViewController.view, @"LoadingDiscover");
}

- (void)testLoadingMastercard {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerMastercard];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    STPSnapshotVerifyView(challengeResponseViewController.view, @"LoadingMastercard");
}

- (void)testLoadingVisa {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerVisa];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    STPSnapshotVerifyView(challengeResponseViewController.view, @"LoadingVisa");
}

- (STDSChallengeResponseViewController *)challengeResponseViewControllerForResponse:(id<STDSChallengeResponse>)response directoryServer:(STDSDirectoryServer)directoryServer {
    STDSImageLoader *imageLoader = [[STDSImageLoader alloc] initWithURLSession:NSURLSession.sharedSession];

    STDSChallengeResponseViewController *vc = [[STDSChallengeResponseViewController alloc] initWithUICustomization:[STDSUICustomization defaultSettings] imageLoader:imageLoader directoryServer:directoryServer analyticsDelegate:nil];
    [vc setChallengeResponse:response animated:NO];
    return vc;
}

- (void)waitForChallengeResponseTimer {
    (void)[XCTWaiter waitForExpectations:@[[self expectationWithDescription:@""]] timeout:2.5];
}

@end
