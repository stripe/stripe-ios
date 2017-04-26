//
//  STPAddSourceViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Ben Guo on 4/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>
#import "STPAddSourceViewController+Private.h"
#import "STPFixtures.h"
#import "STPLocalizationUtils+STPTestAdditions.h"
#import "STPSource+Private.h"

@interface STPAddSourceViewControllerLocalizationTests : FBSnapshotTestCase

@end

@interface STPAddSourceViewController (Testing)
@property(nonatomic) UITableView *tableView;
@end

@implementation STPAddSourceViewControllerLocalizationTests

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (void)performSnapshotTestForLanguage:(NSString *)language sourceType:(STPSourceType)sourceType {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.availablePaymentMethodTypes = @[[STPPaymentMethodType card],
                                           [STPPaymentMethodType sepaDebit]];
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.shippingType = STPShippingTypeShipping;
    STPTheme *theme = [STPTheme defaultTheme];

    [STPLocalizationUtils overrideLanguageTo:language];

    STPAddSourceViewController *sut = [[STPAddSourceViewController alloc] initWithSourceType:sourceType configuration:config theme:theme];
    sut.shippingAddress = [STPAddress new];
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    navController.view.frame = CGRectMake(0, 0, 320, sut.tableView.contentSize.height);

    NSString *sourceTypeString = [STPSource stringFromType:sourceType];
    FBSnapshotVerifyView(navController.view, sourceTypeString);

    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    [self performSnapshotTestForLanguage:@"de" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"de" sourceType:STPSourceTypeSEPADebit];
}

- (void)testEnglish {
    [self performSnapshotTestForLanguage:@"en" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"en" sourceType:STPSourceTypeSEPADebit];
}

- (void)testSpanish {
    [self performSnapshotTestForLanguage:@"es" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"es" sourceType:STPSourceTypeSEPADebit];
}

- (void)testFrench {
    [self performSnapshotTestForLanguage:@"fr" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"fr" sourceType:STPSourceTypeSEPADebit];
}

- (void)testItalian {
    [self performSnapshotTestForLanguage:@"it" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"it" sourceType:STPSourceTypeSEPADebit];
}

- (void)testJapanese {
    [self performSnapshotTestForLanguage:@"ja" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"ja" sourceType:STPSourceTypeSEPADebit];
}

- (void)testDutch {
    [self performSnapshotTestForLanguage:@"nl" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"nl" sourceType:STPSourceTypeSEPADebit];
}

- (void)testChinese {
    [self performSnapshotTestForLanguage:@"zh-Hans" sourceType:STPSourceTypeCard];
    [self performSnapshotTestForLanguage:@"zh-Hans" sourceType:STPSourceTypeSEPADebit];
}

@end
