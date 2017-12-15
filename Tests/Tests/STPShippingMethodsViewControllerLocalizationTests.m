//
//  STPShippingMethodsViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Ben Guo on 11/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>

#import "FBSnapshotTestCase+STPViewControllerLoading.h"
#import "STPAddressViewModel.h"
#import "STPAddressFieldTableViewCell.h"
#import "STPLocalizationUtils.h"
#import "STPBundleLocator.h"
#import "STPLocalizationUtils+STPTestAdditions.h"
#import "STPShippingMethodsViewController.h"

@interface STPShippingMethodsViewController (TestsPrivate)
@property (nonatomic) UITableView *tableView;
@end

@interface STPShippingMethodsViewControllerLocalizationTests : FBSnapshotTestCase

@end

@implementation STPShippingMethodsViewControllerLocalizationTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    [STPLocalizationUtils overrideLanguageTo:language];

    PKShippingMethod *method1 = [[PKShippingMethod alloc] init];
    method1.label = @"UPS Ground";
    method1.detail = @"Arrives in 3-5 days";
    method1.amount = [NSDecimalNumber decimalNumberWithString:@"0.00"];
    method1.identifier = @"ups_ground";
    PKShippingMethod *method2 = [[PKShippingMethod alloc] init];
    method2.label = @"FedEx";
    method2.detail = @"Arrives tomorrow";
    method2.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    method2.identifier = @"fedex";

    STPShippingMethodsViewController *shippingVC = [[STPShippingMethodsViewController alloc]  initWithShippingMethods:@[method1, method2] selectedShippingMethod:method1 currency:@"usd" theme:[STPTheme defaultTheme]];
    UIView *viewToTest = [self stp_preparedAndSizedViewForSnapshotTestFromViewController:shippingVC];
    FBSnapshotVerifyView(viewToTest, nil);
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
