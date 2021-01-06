//
//  STDSChallengeResponseViewControllerSnapshotTests.m
//  Stripe3DS2DemoUITests
//
//  Created by Andrew Harrison on 3/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import FBSnapshotTestCase;
#import <XCTest/XCTest.h>

#import "STDSChallengeResponseViewController.h"
#import "STDSChallengeResponseObject+TestObjects.h"

@interface STDSChallengeResponseViewControllerSnapshotTests: FBSnapshotTestCase

@end

@implementation STDSChallengeResponseViewControllerSnapshotTests

- (void)setUp {
    [super setUp];
    
    /// Recorded on an iPhone XR running iOS 12.1
    self.recordMode = NO;
}

- (void)testVerifyTextChallengeDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject textChallengeResponseWithWhitelist:NO resendCode:NO] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    FBSnapshotVerifyView(challengeResponseViewController.view, @"TextChallengeResponse");
}

- (void)testVerifySingleSelectDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject singleSelectChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    FBSnapshotVerifyView(challengeResponseViewController.view, @"SingleSelectResponse");
}

- (void)testVerifyMultiSelectDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject multiSelectChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    FBSnapshotVerifyView(challengeResponseViewController.view, @"MultiSelectResponse");
}

- (void)testVerifyOOBDesign {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:[STDSChallengeResponseObject OOBChallengeResponse] directoryServer:STDSDirectoryServerCustom];
    [challengeResponseViewController view];
    
    [self waitForChallengeResponseTimer];
    
    FBSnapshotVerifyView(challengeResponseViewController.view, @"OOBResponse");
}

- (void)testLoadingAmex {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerAmex];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    FBSnapshotVerifyView(challengeResponseViewController.view, @"LoadingAmex");
}

- (void)testLoadingDiscover {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerDiscover];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    FBSnapshotVerifyView(challengeResponseViewController.view, @"LoadingDiscover");
}

- (void)testLoadingMastercard {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerMastercard];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    FBSnapshotVerifyView(challengeResponseViewController.view, @"LoadingMastercard");
}

- (void)testLoadingVisa {
    STDSChallengeResponseViewController *challengeResponseViewController = [self challengeResponseViewControllerForResponse:nil directoryServer:STDSDirectoryServerVisa];
    [challengeResponseViewController view];
    [challengeResponseViewController setLoading];

    FBSnapshotVerifyView(challengeResponseViewController.view, @"LoadingVisa");
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
