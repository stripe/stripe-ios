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

/**
 Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
 @param view The view to snapshot.
 @param identifier An optional identifier, used if there are multiple snapshot tests in a given -test method.
 */
#define STPSnapshotVerifyView(view__, identifier__) \
FBSnapshotVerifyViewWithPixelOptions(view__, identifier__, FBSnapshotTestCaseDefaultSuffixes(), 0.02, 0)

@interface STDSChallengeResponseViewControllerSnapshotTests: FBSnapshotTestCase

@end

@implementation STDSChallengeResponseViewControllerSnapshotTests

- (void)setUp {
    [super setUp];
    
    /// Recorded on an iPhone 12 Mini running iOS 15.4
//    self.recordMode = YES;
}

- (void)testVerifyTextChallengeDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:NO] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];

    STPSnapshotVerifyView(challengeResponseViewController.view, @"TextChallengeResponse");
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

    STDSChallengeResponseViewController *vc = [[STDSChallengeResponseViewController alloc] initWithUICustomization:[STDSUICustomization defaultSettings] imageLoader:imageLoader directoryServer:directoryServer];
    [vc setChallengeResponse:response animated:NO];
    return vc;
}

- (void)waitForChallengeResponseTimer {
    (void)[XCTWaiter waitForExpectations:@[[self expectationWithDescription:@""]] timeout:2.5];
}

@end
