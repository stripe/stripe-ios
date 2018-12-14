//
//  ViewController.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "ViewController.h"

#import "MockCustomerContext.h"
#import "STPAddCardViewController+Private.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentConfiguration.h"
#import "STPPaymentMethodsViewController.h"
#import "STPShippingAddressViewController.h"

typedef NS_ENUM(NSInteger, LocalizedScreen) {
    LocalizedScreenPaymentCardTextField = 0,
    LocalizedScreenAddCardVCStandard,
    LocalizedScreenAddCardVCPrefilledShipping,
    LocalizedScreenAddCardPrefilledDelivery,
    LocalizedScreenPaymentMethodsVC,
    LocalizedScreenPaymentMethodsVCLoading,
    LocalizedScreenShippingInfoVC,
};

static NSString * TitleForLocalizedScreen(LocalizedScreen screen) {
    switch (screen) {
        case LocalizedScreenPaymentCardTextField:
            return @"Payment Card Text Field";
        case LocalizedScreenAddCardVCStandard:
            return @"Add Card VC Standard";
        case LocalizedScreenAddCardVCPrefilledShipping:
            return @"Add Card VC Prefilled Shipping";
        case LocalizedScreenAddCardPrefilledDelivery:
            return @"Add Card VC Prefilled Delivery";
        case LocalizedScreenPaymentMethodsVC:
            return @"Payment Methods VC";
        case LocalizedScreenPaymentMethodsVCLoading:
            return @"Payment Methods VC Loading";
        case LocalizedScreenShippingInfoVC:
            return @"Shipping Info VC";
    }
}


@interface ViewController () <STPAddCardViewControllerDelegate, STPPaymentMethodsViewControllerDelegate>

@property NSArray<NSNumber *> *screenTypes;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.screenTypes = @[
                         @(LocalizedScreenPaymentCardTextField),
                         @(LocalizedScreenAddCardVCStandard),
                         @(LocalizedScreenAddCardVCPrefilledShipping),
                         @(LocalizedScreenAddCardPrefilledDelivery),
                         @(LocalizedScreenPaymentMethodsVC),
                         @(LocalizedScreenPaymentMethodsVCLoading),
                         @(LocalizedScreenShippingInfoVC),
                         ];
}


- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.screenTypes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    LocalizedScreen screenType = [self.screenTypes[indexPath.row] integerValue];

    cell.textLabel.text = TitleForLocalizedScreen(screenType);
    return cell;
}


- (BOOL)tableView:(__unused UITableView *)tableView canEditRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(__unused UITableView *)tableView didSelectRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    LocalizedScreen screenType = [self.screenTypes[indexPath.row] integerValue];
    UIViewController *vc = nil;
        switch (screenType) {
            case LocalizedScreenPaymentCardTextField:
            {
                STPPaymentCardTextField *cardTextField = [[STPPaymentCardTextField alloc] init];
                cardTextField.postalCodeEntryEnabled = YES;
                cardTextField.translatesAutoresizingMaskIntoConstraints = false;
                UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cardTextFieldViewControllerDidSelectDone)];
                doneItem.accessibilityIdentifier = @"CardFieldViewControllerDoneButtonIdentifier";
                vc = [[UIViewController alloc] init];
                vc.navigationItem.leftBarButtonItem = doneItem;
                vc.view.backgroundColor = [UIColor whiteColor];
                [vc.view addSubview:cardTextField];
                [NSLayoutConstraint activateConstraints:@[
                                                          [cardTextField.centerYAnchor constraintEqualToAnchor:vc.view.centerYAnchor],
                                                          [cardTextField.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor constant:15],
                                                          [cardTextField.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor constant:-15],
                                                          [cardTextField.heightAnchor constraintEqualToConstant:50],
                                                          ]];

            }
                break;

            case LocalizedScreenAddCardVCStandard:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                STPAddCardViewController *addCardVC = [[STPAddCardViewController alloc] initWithConfiguration:configuration theme:[STPTheme defaultTheme]];
                addCardVC.alwaysShowScanCardButton = YES;
                addCardVC.alwaysEnableDoneButton = YES;
                addCardVC.delegate = self;
                vc = addCardVC;
            }
                break;

            case LocalizedScreenAddCardVCPrefilledShipping:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.shippingType = STPShippingTypeShipping;
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                STPAddCardViewController *addCardVC = [[STPAddCardViewController alloc] initWithConfiguration:configuration theme:[STPTheme defaultTheme]];
                addCardVC.shippingAddress = [[STPAddress alloc] init];
                addCardVC.shippingAddress.line1 = @"1"; // trigger "use shipping address" button
                addCardVC.delegate = self;
                vc = addCardVC;
            }
                break;

            case LocalizedScreenAddCardPrefilledDelivery:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.shippingType = STPShippingTypeDelivery;
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                STPAddCardViewController *addCardVC = [[STPAddCardViewController alloc] initWithConfiguration:configuration theme:[STPTheme defaultTheme]];
                addCardVC.shippingAddress = [[STPAddress alloc] init];
                addCardVC.shippingAddress.line1 = @"1"; // trigger "use delivery address" button
                addCardVC.delegate = self;
                vc = addCardVC;
            }
                break;

            case LocalizedScreenPaymentMethodsVC:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.additionalPaymentMethods = STPPaymentMethodTypeAll;
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                configuration.appleMerchantIdentifier = @"dummy-merchant-id";
                vc = [[STPPaymentMethodsViewController alloc] initWithConfiguration:configuration
                                                                              theme:[STPTheme defaultTheme]
                                                                    customerContext:[[MockCustomerContext alloc] init]
                                                                           delegate:self];
            }
                break;
            case LocalizedScreenPaymentMethodsVCLoading:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.additionalPaymentMethods = STPPaymentMethodTypeAll;
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                configuration.appleMerchantIdentifier = @"dummy-merchant-id";
                MockCustomerContext *customerContext = [[MockCustomerContext alloc] init];
                customerContext.neverRetrieveCustomer = YES;
                vc = [[STPPaymentMethodsViewController alloc] initWithConfiguration:configuration
                                                                              theme:[STPTheme defaultTheme]
                                                                    customerContext:customerContext
                                                                           delegate:self];
            }
                break;
//            case LocalizedScreenShippingInfoVC:
//                return @"Shipping Info VC";
            default: break;
        }
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - Card Text Field

- (void)cardTextFieldViewControllerDidSelectDone {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - STPAddCardViewControllerDelegate

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController
               didCreateToken:(__unused STPToken *)token
                   completion:(__unused STPErrorBlock)completion {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - STPPaymentMethodsViewControllerDelegate

- (void)paymentMethodsViewController:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)paymentMethodsViewControllerDidFinish:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)paymentMethodsViewControllerDidCancel:(__unused STPPaymentMethodsViewController *)paymentMethodsViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}


@end

