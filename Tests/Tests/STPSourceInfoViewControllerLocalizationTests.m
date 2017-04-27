//
//  STPSourceInfoViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Ben Guo on 4/27/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>
#import "STPFixtures.h"
#import "STPLocalizationUtils+STPTestAdditions.h"
#import "STPSourceInfoViewController.h"
#import "STPSource+Private.h"

@interface STPSourceInfoViewControllerLocalizationTests : FBSnapshotTestCase

@end

@interface STPSourceInfoViewController (Testing)
@property (nonatomic) UITableView *tableView;
@end

@implementation STPSourceInfoViewControllerLocalizationTests

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    STPTheme *theme = [STPTheme defaultTheme];
    NSArray *sourceTypesToTest = @[
                                   @(STPSourceTypeBancontact),
                                   @(STPSourceTypeGiropay),
                                   @(STPSourceTypeIDEAL),
                                   @(STPSourceTypeSofort),
                                   ];

    [STPLocalizationUtils overrideLanguageTo:language];
    for (NSUInteger i = 0; i < sourceTypesToTest.count; i++) {
        STPSourceType sourceType = [sourceTypesToTest[i] integerValue];
        STPSourceInfoViewController *sut = [[STPSourceInfoViewController alloc] initWithSourceType:sourceType amount:1099 configuration:config prefilledInformation:nil sourceInformation:nil theme:theme completion:^(__unused STPSourceParams *sourceParams) {
        }];
        UINavigationController *navController = [UINavigationController new];
        navController.navigationBar.translucent = NO;
        navController.view.frame = CGRectMake(0, 0, 320, 750);
        [navController pushViewController:sut animated:NO];
        [navController.view layoutIfNeeded];
        CGFloat height = sut.tableView.contentSize.height + navController.navigationBar.frame.size.height;
        navController.view.frame = CGRectMake(0, 0, 320, height);
        FBSnapshotVerifyView(navController.view, [STPSource stringFromType:sourceType]);
    }
    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    [self performSnapshotTestForLanguage:@"de"];
}

- (void)testEnglish {
    [self performSnapshotTestForLanguage:@"en"];
}

- (void)testSpanish {
    [self performSnapshotTestForLanguage:@"es"];
}

- (void)testFrench {
    [self performSnapshotTestForLanguage:@"fr"];
}

- (void)testItalian {
    [self performSnapshotTestForLanguage:@"it"];
}

- (void)testJapanese {
    [self performSnapshotTestForLanguage:@"ja"];
}

- (void)testDutch {
    [self performSnapshotTestForLanguage:@"nl"];
}

- (void)testChinese {
    [self performSnapshotTestForLanguage:@"zh-Hans"];
}

@end
