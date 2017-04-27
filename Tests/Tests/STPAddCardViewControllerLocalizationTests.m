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
#import "STPAddCardViewController+Private.h"
#import "STPAddressViewModel.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPBundleLocator.h"
#import "STPFixtures.h"
#import "STPLocalizationUtils.h"
#import "STPLocalizationUtils+STPTestAdditions.h"

@interface STPAddCardViewControllerLocalizationTests : FBSnapshotTestCase

@end

@interface STPAddCardViewController (TestsPrivate)
@property(nonatomic) UITableView *tableView;
@property(nonatomic) STPAddressViewModel<STPAddressFieldTableViewCellDelegate> *addressViewModel;
@end

@implementation STPAddCardViewControllerLocalizationTests

- (void)setUp {
    [super setUp];

    self.recordMode = YES;
}

- (void)performSnapshotTestForLanguage:(NSString *)language delivery:(BOOL)delivery {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.availablePaymentMethodTypes = @[[STPPaymentMethodType applePay],
                                           [STPPaymentMethodType card]];
    config.shippingType = (delivery) ? STPShippingTypeDelivery : STPShippingTypeShipping;

    [STPLocalizationUtils overrideLanguageTo:language];
    
    STPAddCardViewController *addCardVC = [[STPAddCardViewController alloc] initWithConfiguration:config
                                                                                            theme:[STPTheme defaultTheme]];
    addCardVC.shippingAddress = [STPAddress new];
    
    UINavigationController *navController = [UINavigationController new];
    navController.navigationBar.translucent = NO;
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:addCardVC animated:NO];
    [navController.view layoutIfNeeded];
    CGFloat height = addCardVC.tableView.contentSize.height + navController.navigationBar.frame.size.height;
    navController.view.frame = CGRectMake(0, 0, 320, height);

    if (delivery) {
        addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"INVALID";
        FBSnapshotVerifyView(navController.view, @"delivery");
    } else {
        /**
         This method rejects nil or empty country codes to stop strange looking behavior
         when scrolling to the top "unset" position in the picker, so put in
         an invalid country code instead to test seeing the "Country" placeholder
         */
        addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"INVALID";
        FBSnapshotVerifyView(navController.view, @"no_country");

        // Strings for state and postal code are different for US addresses
        addCardVC.addressViewModel.addressFieldTableViewCountryCode = @"US";
        FBSnapshotVerifyView(navController.view, @"US");
    }

    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    [self performSnapshotTestForLanguage:@"de" delivery:NO];
    [self performSnapshotTestForLanguage:@"de" delivery:YES];
}

- (void)testEnglish {
    [self performSnapshotTestForLanguage:@"en" delivery:NO];
    [self performSnapshotTestForLanguage:@"en" delivery:YES];
}

- (void)testSpanish {
    [self performSnapshotTestForLanguage:@"es" delivery:NO];
    [self performSnapshotTestForLanguage:@"es" delivery:YES];
}

- (void)testFrench {
    [self performSnapshotTestForLanguage:@"fr" delivery:NO];
    [self performSnapshotTestForLanguage:@"fr" delivery:YES];
}

- (void)testItalian {
    [self performSnapshotTestForLanguage:@"it" delivery:NO];
    [self performSnapshotTestForLanguage:@"it" delivery:YES];
}

- (void)testJapanese {
    [self performSnapshotTestForLanguage:@"ja" delivery:NO];
    [self performSnapshotTestForLanguage:@"ja" delivery:YES];
}

- (void)testDutch {
    [self performSnapshotTestForLanguage:@"nl" delivery:NO];
    [self performSnapshotTestForLanguage:@"nl" delivery:YES];
}

- (void)testChinese {
    [self performSnapshotTestForLanguage:@"zh-Hans" delivery:NO];
    [self performSnapshotTestForLanguage:@"zh-Hans" delivery:YES];
}


@end
