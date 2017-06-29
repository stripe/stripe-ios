//
//  STPPaymentMethodsViewControllerLocalizationTests.m
//  Stripe
//
//  Created by Brian Dorfman on 10/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <Stripe/Stripe.h>

#import "STPFixtures.h"
#import "STPMocks.h"
#import "STPLocalizationUtils+STPTestAdditions.h"

@interface STPPaymentMethodsViewControllerLocalizationTests : FBSnapshotTestCase

@end

@implementation STPPaymentMethodsViewControllerLocalizationTests

//- (void)setUp {
//    [super setUp];
//    
//    self.recordMode = YES;
//}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.additionalPaymentMethods = STPPaymentMethodTypeAll;
    STPTheme *theme = [STPTheme defaultTheme];
    id customerContext = [STPMocks staticCustomerContext];
    id delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    [STPLocalizationUtils overrideLanguageTo:language];
    STPPaymentMethodsViewController *paymentMethodsVC = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:theme
                                                                                                       customerContext:customerContext
                                                                                                              delegate:delegate];

    UIViewController *rootVC = [UIViewController new];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentMethodsVC];

    UIWindow *testWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];

    testWindow.rootViewController = rootVC;
    [rootVC presentViewController:navController animated:NO completion:^{

        FBSnapshotVerifyView(testWindow, nil)

        [STPLocalizationUtils overrideLanguageTo:nil];
    }];

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
