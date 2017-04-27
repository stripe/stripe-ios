//
//  STPShippingAddressViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Ben Guo on 11/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>
#import "STPAddressViewModel.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPBundleLocator.h"
#import "STPFixtures.h"
#import "STPLocalizationUtils.h"
#import "STPLocalizationUtils+STPTestAdditions.h"

typedef NS_ENUM(NSUInteger, STPShippingAddressLocalizationTestType) {
    STPShippingAddressLocalizationTestTypeShipping,
    STPShippingAddressLocalizationTestTypeShippingContact,
    STPShippingAddressLocalizationTestTypeDelivery,
    STPShippingAddressLocalizationTestTypeMax,
};

@interface STPShippingAddressViewController (TestsPrivate)
@property(nonatomic) UITableView *tableView;
@property(nonatomic) STPAddressViewModel<STPAddressFieldTableViewCellDelegate> *addressViewModel;
@end

@interface STPShippingAddressViewControllerLocalizationTests : FBSnapshotTestCase

@end

@implementation STPShippingAddressViewControllerLocalizationTests

- (void)setUp {
    [super setUp];

    self.recordMode = YES;
}

- (void)performSnapshotTestForLanguage:(NSString *)language testType:(STPShippingAddressLocalizationTestType)testType {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredShippingAddressFields = PKAddressFieldAll;
    if (testType == STPShippingAddressLocalizationTestTypeShippingContact) {
        config.requiredShippingAddressFields = PKAddressFieldEmail;
    }
    STPShippingType shippingType = STPShippingTypeShipping;
    if (testType == STPShippingAddressLocalizationTestTypeDelivery) {
        shippingType = STPShippingTypeDelivery;
    }
    config.shippingType = shippingType;

    [STPLocalizationUtils overrideLanguageTo:language];
    STPUserInformation *info = [STPUserInformation new];
    info.billingAddress = [STPAddress new];

    STPShippingAddressViewController *shippingVC = [[STPShippingAddressViewController alloc] initWithConfiguration:config
                                                                                                             theme:[STPTheme defaultTheme]
                                                                                                          currency:nil
                                                                                                   shippingAddress:nil
                                                                                            selectedShippingMethod:nil
                                                                                              prefilledInformation:info];

    UINavigationController *navController = [UINavigationController new];
    navController.navigationBar.translucent = NO;
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:shippingVC animated:NO];
    [navController.view layoutIfNeeded];
    CGFloat height = shippingVC.tableView.contentSize.height + navController.navigationBar.frame.size.height;
    navController.view.frame = CGRectMake(0, 0, 320, height);

    /**
     This method rejects nil or empty country codes to stop strange looking behavior
     when scrolling to the top "unset" position in the picker, so put in
     an invalid country code instead to test seeing the "Country" placeholder
     */
    shippingVC.addressViewModel.addressFieldTableViewCountryCode = @"INVALID";
    NSString *identifier;
    switch (testType) {
        case STPShippingAddressLocalizationTestTypeShipping:
            identifier = @"shipping";
            break;
        case STPShippingAddressLocalizationTestTypeShippingContact:
            identifier = @"shipping_contact";
            break;
        case STPShippingAddressLocalizationTestTypeDelivery:
            identifier = @"delivery";
            break;
        case STPShippingAddressLocalizationTestTypeMax:
            break;
    }
    FBSnapshotVerifyView(navController.view, identifier);

    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"de" testType:i];
    }
}

- (void)testEnglish {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"en" testType:i];
    }
}

- (void)testSpanish {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"es" testType:i];
    }
}

- (void)testFrench {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"fr" testType:i];
    }
}

- (void)testItalian {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"it" testType:i];
    }
}

- (void)testJapanese {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"ja" testType:i];
    }
}

- (void)testDutch {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"nl" testType:i];
    }
}

- (void)testChinese {
    for (NSUInteger i = 0; i < STPShippingAddressLocalizationTestTypeMax; i++) {
        [self performSnapshotTestForLanguage:@"zh-Hans" testType:i];
    }
}

@end
