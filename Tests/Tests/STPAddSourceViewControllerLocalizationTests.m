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
#import "STPAddressViewModel.h"
#import "STPAddSourceViewController+Private.h"
#import "STPFixtures.h"
#import "STPLocalizationUtils+STPTestAdditions.h"
#import "STPSource+Private.h"

typedef NS_ENUM(NSUInteger, STPAddSourceLocalizationTestType) {
    STPAddSourceLocalizationTestTypeSEPADebit,
    STPAddSourceLocalizationTestTypeCard,
    STPAddSourceLocalizationTestTypeUseDelivery,
    STPAddSourceLocalizationTestTypeMax,
};

@interface STPAddSourceViewControllerLocalizationTests : FBSnapshotTestCase
@end

@interface STPAddSourceViewController (Testing)
@property(nonatomic) UITableView *tableView;
@property(nonatomic) STPAddressViewModel<STPAddressFieldTableViewCellDelegate> *addressViewModel;
@end

@implementation STPAddSourceViewControllerLocalizationTests

- (void)setUp {
    [super setUp];
    self.recordMode = YES;
}

- (void)performSnapshotTestForLanguage:(NSString *)language testType:(STPAddSourceLocalizationTestType)testType {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.availablePaymentMethodTypes = @[[STPPaymentMethodType card],
                                           [STPPaymentMethodType sepaDebit]];
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    STPShippingType shippingType = STPShippingTypeShipping;
    if (testType == STPAddSourceLocalizationTestTypeUseDelivery) {
        shippingType = STPShippingTypeDelivery;
    }
    config.shippingType = shippingType;
    STPTheme *theme = [STPTheme defaultTheme];

    [STPLocalizationUtils overrideLanguageTo:language];

    STPSourceType sourceType = (testType == STPAddSourceLocalizationTestTypeSEPADebit) ? STPSourceTypeSEPADebit : STPSourceTypeCard;
    STPAddSourceViewController *sut = [[STPAddSourceViewController alloc] initWithSourceType:sourceType configuration:config theme:theme];
    sut.shippingAddress = [STPAddress new];
    UINavigationController *navController = [UINavigationController new];
    navController.navigationBar.translucent = NO;
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    CGFloat height = sut.tableView.contentSize.height + navController.navigationBar.frame.size.height;
    navController.view.frame = CGRectMake(0, 0, 320, height);

    switch (testType) {
        case STPAddSourceLocalizationTestTypeSEPADebit:
            FBSnapshotVerifyView(navController.view, @"sepa_debit");
            break;
        case STPAddSourceLocalizationTestTypeUseDelivery:
            FBSnapshotVerifyView(navController.view, @"use_delivery");
            break;
        case STPAddSourceLocalizationTestTypeCard: {
            /**
             This method rejects nil or empty country codes to stop strange looking behavior
             when scrolling to the top "unset" position in the picker, so put in
             an invalid country code instead to test seeing the "Country" placeholder
             */
            sut.addressViewModel.addressFieldTableViewCountryCode = @"INVALID";
            FBSnapshotVerifyView(navController.view, @"card_no_country");

            // Strings for state and postal code are different for US addresses
            sut.addressViewModel.addressFieldTableViewCountryCode = @"US";
            FBSnapshotVerifyView(navController.view, @"card_US");
            break;
        case STPAddSourceLocalizationTestTypeMax:
            break;
        }
    }

    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"de" testType:i];
    }
}

- (void)testEnglish {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"en" testType:i];
    }
}

- (void)testSpanish {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"es" testType:i];
    }
}

- (void)testFrench {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"fr" testType:i];
    }
}

- (void)testItalian {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"it" testType:i];
    }
}

- (void)testJapanese {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"ja" testType:i];
    }
}

- (void)testDutch {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"nl" testType:i];
    }
}

- (void)testChinese {
    for (NSUInteger i = 0; i < STPAddSourceLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"zh-Hans" testType:i];
    }
}

@end
