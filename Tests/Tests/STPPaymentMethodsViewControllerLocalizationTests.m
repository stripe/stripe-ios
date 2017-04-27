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
#import "STPLocalizationUtils+STPTestAdditions.h"
#import "STPMocks.h"
#import "STPPaymentMethodsInternalViewController.h"
#import "STPTestUtils.h"

@interface STPPaymentMethodsViewControllerLocalizationTests : FBSnapshotTestCase

@end

@interface STPPaymentMethodsViewController (Testing)
@property (nonatomic) STPPaymentMethodsInternalViewController *internalViewController;
@end

@interface STPPaymentMethodsInternalViewController (Testing)
@property (nonatomic) UITableView *tableView;
@end

@implementation STPPaymentMethodsViewControllerLocalizationTests

- (void)setUp {
    [super setUp];
    
    self.recordMode = YES;
}

- (STPCustomer *)buildCustomer {
    NSMutableDictionary *customer = [[STPTestUtils jsonNamed:@"Customer"] mutableCopy];
    NSMutableDictionary *sources = [customer[@"sources"] mutableCopy];
    NSMutableDictionary *sepaSource = [[STPTestUtils jsonNamed:@"SEPADebitSource"] mutableCopy];
    sepaSource[@"id"] = @"foo";
    NSMutableDictionary *cardSource = [[STPTestUtils jsonNamed:@"CardSource"] mutableCopy];
    cardSource[@"id"] = @"bar";
    sources[@"data"] = @[sepaSource, cardSource];
    customer[@"default_source"] = cardSource[@"id"];
    customer[@"sources"] = sources;

    STPCustomerDeserializer *deserializer = [[STPCustomerDeserializer alloc] initWithJSONResponse:customer];
    return deserializer.customer;
}

- (void)performSnapshotTestForLanguage:(NSString *)language {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.companyName = @"Test Company";
    config.appleMerchantIdentifier = @"fake_merchant_id";
    config.requiredBillingAddressFields = STPBillingAddressFieldsFull;
    config.availablePaymentMethodTypes = @[[STPPaymentMethodType applePay],
                                           [STPPaymentMethodType card],
                                           [STPPaymentMethodType bancontact],
                                           [STPPaymentMethodType giropay],
                                           [STPPaymentMethodType ideal],
                                           [STPPaymentMethodType sepaDebit],
                                           [STPPaymentMethodType sofort],
                                           ];
    STPTheme *theme = [STPTheme defaultTheme];
    id apiAdapter = [STPMocks staticAPIAdapterWithCustomer:[self buildCustomer]];
    id delegate = OCMProtocolMock(@protocol(STPPaymentMethodsViewControllerDelegate));
    [STPLocalizationUtils overrideLanguageTo:language];

    STPPaymentMethodsViewController *sut = [[STPPaymentMethodsViewController alloc] initWithConfiguration:config
                                                                                                                 theme:theme
                                                                                                            apiAdapter:apiAdapter
                                                                                                              delegate:delegate];

    UINavigationController *navController = [UINavigationController new];
    navController.navigationBar.translucent = NO;
    navController.view.frame = CGRectMake(0, 0, 320, 750);
    [navController pushViewController:sut animated:NO];
    [navController.view layoutIfNeeded];
    CGFloat height = sut.internalViewController.tableView.contentSize.height + navController.navigationBar.frame.size.height;
    navController.view.frame = CGRectMake(0, 0, 320, height);
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

@end
