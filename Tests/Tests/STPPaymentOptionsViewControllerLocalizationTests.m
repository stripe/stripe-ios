//
//  STPPaymentOptionsViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>

#import "FBSnapshotTestCase+STPViewControllerLoading.h"
#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPLocalizationUtils+STPTestAdditions.h"

@interface STPPaymentOptionsViewControllerLocalizationTests : FBSnapshotTestCase
@end

@implementation STPPaymentOptionsViewControllerLocalizationTests

//- (void)setUp {
//    [super setUp];
//
//    self.recordMode = YES;
//}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.additionalPaymentOptions = STPPaymentOptionTypeAll;
    STPTheme *theme = [STPTheme defaultTheme];
    NSArray *paymentMethods = @[[STPFixtures paymentMethod], [STPFixtures paymentMethod]];
    id customerContext = [STPMocks staticCustomerContextWithCustomer:[STPFixtures customerWithCardTokenAndSourceSources] paymentMethods:paymentMethods];
    id delegate = OCMProtocolMock(@protocol(STPPaymentOptionsViewControllerDelegate));
    [STPLocalizationUtils overrideLanguageTo:language];
    STPPaymentOptionsViewController *paymentOptionsVC = [[STPPaymentOptionsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:theme
                                                                                                       customerContext:customerContext
                                                                                                              delegate:delegate];


    UIView *viewToTest = [self stp_preparedAndSizedViewForSnapshotTestFromViewController:paymentOptionsVC];

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
