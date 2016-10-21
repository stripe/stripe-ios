//
//  STPAddCardViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>
#import "STPSwitchTableViewCell.h"
#import "STPAddressViewModel.h"
#import "STPAddressFieldTableViewCell.h"

@interface STPAddCardViewControllerLocalizationTests : FBSnapshotTestCase

@end

@interface STPAddCardViewController (TestsPrivate)
@property(nonatomic) UITableView *tableView;
@property(nonatomic) BOOL forceEnableRememberMeForTesting;
@property(nonatomic) STPAddressViewModel<STPAddressFieldTableViewCellDelegate> *addressViewModel;
@end

@implementation STPAddCardViewControllerLocalizationTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    
    STPPaymentConfiguration *config = [STPPaymentConfiguration new];
    config.publishableKey = @"test";
    config.companyName = @"Test Company";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.additionalPaymentMethods = STPPaymentMethodTypeAll;
    config.smsAutofillDisabled = NO;
    
    [STPLocalizationUtils overrideLanguageTo:language];
    
    STPAddCardViewController *addCardVC = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                            theme:[STPTheme defaultTheme]];
    
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:addCardVC animated:NO];
    addCardVC.forceEnableRememberMeForTesting = YES;
    [navController.view layoutIfNeeded];
    navController.view.frame = CGRectMake(0, 0, 320, addCardVC.tableView.contentSize.height);

    addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"US";
    FBSnapshotVerifyView(navController.view, @"US");
    
    addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"GB";
    FBSnapshotVerifyView(navController.view, @"GB");
    
    addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"CA";
    FBSnapshotVerifyView(navController.view, @"CA");

    addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"MX";
    FBSnapshotVerifyView(navController.view, @"MX");
    
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
