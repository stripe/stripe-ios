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

@interface STPShippingAddressViewController (TestsPrivate)
@property (nonatomic) UITableView *tableView;
@property (nonatomic) STPAddressViewModel<STPAddressFieldTableViewCellDelegate> *addressViewModel;
@end

@interface STPShippingAddressViewControllerLocalizationTests : FBSnapshotTestCase

@end

@implementation STPShippingAddressViewControllerLocalizationTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)performSnapshotTestForLanguage:(NSString *)language shippingType:(STPShippingType)shippingType contact:(BOOL)contact {
    NSString *identifier = (shippingType == STPShippingTypeShipping) ? @"shipping" : @"delivery";
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredShippingAddressFields = PKAddressFieldAll;
    if (contact) {
        config.requiredShippingAddressFields = PKAddressFieldEmail;
        identifier = @"contact";
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
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:shippingVC animated:NO];
    [navController.view layoutIfNeeded];
    navController.view.frame = CGRectMake(0, 0, 320, shippingVC.tableView.contentSize.height);

    /**
     This method rejects nil or empty country codes to stop strange looking behavior
     when scrolling to the top "unset" position in the picker, so put in
     an invalid country code instead to test seeing the "Country" placeholder
     */
    shippingVC.addressViewModel.addressFieldTableViewCountryCode = @"INVALID";
    FBSnapshotVerifyView(navController.view, identifier);

    [STPLocalizationUtils overrideLanguageTo:nil];
}

- (void)testGerman {
    [self performSnapshotTestForLanguage:@"de" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"de" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"de" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testEnglish {
    [self performSnapshotTestForLanguage:@"en" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"en" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"en" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testSpanish {
    [self performSnapshotTestForLanguage:@"es" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"es" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"es" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testFrench {
    [self performSnapshotTestForLanguage:@"fr" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"fr" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"fr" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testItalian {
    [self performSnapshotTestForLanguage:@"it" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"it" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"it" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testJapanese {
    [self performSnapshotTestForLanguage:@"ja" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"ja" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"ja" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testDutch {
    [self performSnapshotTestForLanguage:@"nl" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"nl" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"nl" shippingType:STPShippingTypeDelivery contact:NO];
}

- (void)testChinese {
    [self performSnapshotTestForLanguage:@"zh-Hans" shippingType:STPShippingTypeShipping contact:NO];
    [self performSnapshotTestForLanguage:@"zh-Hans" shippingType:STPShippingTypeShipping contact:YES];
    [self performSnapshotTestForLanguage:@"zh-Hans" shippingType:STPShippingTypeDelivery contact:NO];
}

@end
