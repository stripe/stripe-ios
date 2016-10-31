//
//  STPPaymentMethodsViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>

#import "TestSTPBackendAPIAdapter.h"
#import "STPLocalizationUtils+STPTestAdditions.h"

@interface STPPaymentMethodsViewControllerLocalizationTests : FBSnapshotTestCase <STPPaymentMethodsViewControllerDelegate>

@end

@implementation STPPaymentMethodsViewControllerLocalizationTests

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
    
    STPPaymentMethodsViewController *paymentMethodsVC = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:[STPTheme defaultTheme]
                                                                                                            apiAdapter:[TestSTPBackendAPIAdapter new] 
                                                                                                              delegate:self];
    
    UINavigationController *navController = [UINavigationController new];
    navController.view.frame = CGRectMake(0, 0, 320, 480);
    [navController pushViewController:paymentMethodsVC animated:NO];
    
    FBSnapshotVerifyView(navController.view, nil)
    
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

#pragma mark - Delegate Methods -

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didSelectPaymentMethod:(__unused id<STPPaymentMethod>)paymentMethod {
    
}


- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    
}


- (void)paymentMethodsViewControllerDidFinish:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController {
    
}


@end
