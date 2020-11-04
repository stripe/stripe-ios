//
//  ViewController.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "ViewController.h"

#import "MockCustomerContext.h"






typedef NS_ENUM(NSInteger, LocalizedScreen) {
    LocalizedScreenPaymentCardTextField = 0,
    LocalizedScreenAddCardVCStandard,
    LocalizedScreenAddCardVCPrefilledShipping,
    LocalizedScreenAddCardPrefilledDelivery,
    LocalizedScreenPaymentOptionsVC,
    LocalizedScreenPaymentOptionsVCLoading,
    LocalizedScreenShippingAddressVC,
    LocalizedScreenShippingAddressVCBadAddress,
    LocalizedScreenShippingAddressVCCountryOutsideAvailable,
    LocalizedScreenShippingAddressVCDelivery,
    LocalizedScreenShippingAddressVCContact,
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
        case LocalizedScreenPaymentOptionsVC:
            return @"Payment Options VC";
        case LocalizedScreenPaymentOptionsVCLoading:
            return @"Payment Options VC Loading";
        case LocalizedScreenShippingAddressVC:
            return @"Shipping Address VC";
        case LocalizedScreenShippingAddressVCBadAddress:
            return @"Shipping Address VC Bad Address";
        case LocalizedScreenShippingAddressVCCountryOutsideAvailable:
            return @"Shipping Address VC Country Outside Available";
        case LocalizedScreenShippingAddressVCDelivery:
            return @"Shipping Address VC for Delivery";
        case LocalizedScreenShippingAddressVCContact:
            return @"Shipping Address VC for Contact";
    }
}


@interface ViewController () <STPAddCardViewControllerDelegate, STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate>

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
                         @(LocalizedScreenPaymentOptionsVC),
                         @(LocalizedScreenPaymentOptionsVCLoading),
                         @(LocalizedScreenShippingAddressVC),
                         @(LocalizedScreenShippingAddressVCBadAddress),
                         @(LocalizedScreenShippingAddressVCCountryOutsideAvailable),
                         @(LocalizedScreenShippingAddressVCDelivery),
                         @(LocalizedScreenShippingAddressVCContact),
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

            case LocalizedScreenPaymentOptionsVC:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                configuration.appleMerchantIdentifier = @"dummy-merchant-id";
                vc = [[STPPaymentOptionsViewController alloc] initWithConfiguration:configuration
                                                                              theme:[STPTheme defaultTheme]
                                                                         apiAdapter:[[MockCustomerContext alloc] init]
                                                                           delegate:self];
            }
                break;

            case LocalizedScreenPaymentOptionsVCLoading:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredBillingAddressFields = STPBillingAddressFieldsFull;
                configuration.appleMerchantIdentifier = @"dummy-merchant-id";
                MockCustomerContext *customerContext = [[MockCustomerContext alloc] init];
                customerContext.neverRetrieveCustomer = YES;
                vc = [[STPPaymentOptionsViewController alloc] initWithConfiguration:configuration
                                                                              theme:[STPTheme defaultTheme]
                                                                         apiAdapter:customerContext
                                                                           delegate:self];
            }
                break;

            case LocalizedScreenShippingAddressVC:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredShippingAddressFields = [NSSet setWithObjects:STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name, nil];
                STPUserInformation *prefilledInfo = [[STPUserInformation alloc] init];
                STPAddress *billingAddress = [[STPAddress alloc] init];
                billingAddress.name = @"Test";
                billingAddress.email = @"test@test.com";
                billingAddress.phone = @"9311111111";
                billingAddress.line1 = @"Test";
                billingAddress.line2 = @"Test";
                billingAddress.postalCode = @"1001";
                billingAddress.city = @"Kabul";
                billingAddress.state = @"Kabul";
                billingAddress.country = @"AF";
                prefilledInfo.billingAddress = billingAddress;

                STPShippingAddressViewController *shippingAddressVC = [[STPShippingAddressViewController alloc] initWithConfiguration:configuration
                                                                                                                                theme:[STPTheme defaultTheme]
                                                                                                                             currency:@"usd"
                                                                                                                      shippingAddress:nil
                                                                                                               selectedShippingMethod:nil
                                                                                                                 prefilledInformation:prefilledInfo];
                shippingAddressVC.delegate = self;
                vc = shippingAddressVC;
            }
                break;

            case LocalizedScreenShippingAddressVCBadAddress:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredShippingAddressFields = [NSSet setWithObjects:STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name, nil];
                STPUserInformation *prefilledInfo = [[STPUserInformation alloc] init];
                STPAddress *billingAddress = [[STPAddress alloc] init];
                billingAddress.name = @"Test";
                billingAddress.email = @"test@test.com";
                billingAddress.phone = @"9311111111";
                billingAddress.line1 = @"Test";
                billingAddress.line2 = @"Test";
                billingAddress.postalCode = @"90026";
                billingAddress.city = @"Kabul";
                billingAddress.state = @"Kabul";
                billingAddress.country = @"US"; // We're just going to hard code that "US" country triggers failure below
                prefilledInfo.billingAddress = billingAddress;

                STPShippingAddressViewController *shippingAddressVC = [[STPShippingAddressViewController alloc] initWithConfiguration:configuration
                                                                                                                                theme:[STPTheme defaultTheme]
                                                                                                                             currency:@"usd"
                                                                                                                      shippingAddress:nil
                                                                                                               selectedShippingMethod:nil
                                                                                                                 prefilledInformation:prefilledInfo];
                shippingAddressVC.delegate = self;
                vc = shippingAddressVC;
            }
                break;

            case LocalizedScreenShippingAddressVCCountryOutsideAvailable:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredShippingAddressFields = [NSSet setWithObjects:STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name, nil];
                configuration.availableCountries = [NSSet setWithArray:@[@"BT"]];
                STPUserInformation *prefilledInfo = [[STPUserInformation alloc] init];
                STPAddress *billingAddress = [[STPAddress alloc] init];
                billingAddress.name = @"Test";
                billingAddress.country = @"GB";
                prefilledInfo.billingAddress = billingAddress;
                
                STPShippingAddressViewController *shippingAddressVC = [[STPShippingAddressViewController alloc] initWithConfiguration:configuration
                                                                                                                                theme:[STPTheme defaultTheme]
                                                                                                                             currency:@"usd"
                                                                                                                      shippingAddress:nil
                                                                                                               selectedShippingMethod:nil
                                                                                                                 prefilledInformation:prefilledInfo];
                shippingAddressVC.delegate = self;
                vc = shippingAddressVC;
            }
                break;

            case LocalizedScreenShippingAddressVCDelivery:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.shippingType = STPShippingTypeDelivery;
                configuration.requiredShippingAddressFields = [NSSet setWithObjects:STPContactField.postalAddress, STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name, nil];

                STPShippingAddressViewController *shippingAddressVC = [[STPShippingAddressViewController alloc] initWithConfiguration:configuration
                                                                                                                                theme:[STPTheme defaultTheme]
                                                                                                                             currency:@"usd"
                                                                                                                      shippingAddress:nil
                                                                                                               selectedShippingMethod:nil
                                                                                                                 prefilledInformation:nil];
                shippingAddressVC.delegate = self;
                vc = shippingAddressVC;
            }
                break;

            case LocalizedScreenShippingAddressVCContact:
            {
                STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
                configuration.requiredShippingAddressFields = [NSSet setWithObjects:STPContactField.emailAddress, STPContactField.phoneNumber, STPContactField.name, nil];

                STPShippingAddressViewController *shippingAddressVC = [[STPShippingAddressViewController alloc] initWithConfiguration:configuration
                                                                                                                                theme:[STPTheme defaultTheme]
                                                                                                                             currency:@"usd"
                                                                                                                      shippingAddress:nil
                                                                                                               selectedShippingMethod:nil
                                                                                                                 prefilledInformation:nil];
                shippingAddressVC.delegate = self;
                vc = shippingAddressVC;
            }
                break;

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
       didCreatePaymentMethod:(__unused STPPaymentMethod *)paymentMethod
                   completion:(__unused STPErrorBlock)completion {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - STPPaymentOptionssViewControllerDelegate

- (void)paymentOptionsViewController:(__unused STPPaymentOptionsViewController *)paymentOptionsViewController
              didFailToLoadWithError:(__unused NSError *)error {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)paymentOptionsViewControllerDidFinish:(__unused STPPaymentOptionsViewController *)paymentOptionsViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)paymentOptionsViewControllerDidCancel:(__unused STPPaymentOptionsViewController *)paymentOptionsViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}


#pragma mark - STPShippingAddressViewControllerDelegate

- (void)shippingAddressViewControllerDidCancel:(__unused STPShippingAddressViewController *)addressViewController {
    [self.navigationController popToRootViewControllerAnimated:NO];
}


- (void)shippingAddressViewController:(__unused STPShippingAddressViewController *)addressViewController
                      didEnterAddress:(STPAddress *)address
                           completion:(STPShippingMethodsCompletionBlock)completion {
    PKShippingMethod *upsGround = [[PKShippingMethod alloc] init];
    upsGround.amount = [NSDecimalNumber decimalNumberWithString:@"0"];
    upsGround.label = @"UPS Ground";
    upsGround.detail = @"Arrives in 3-5 days";
    upsGround.identifier = @"ups_ground";
    PKShippingMethod *upsWorldwide = [[PKShippingMethod alloc] init];
    upsWorldwide.amount = [NSDecimalNumber decimalNumberWithString:@"10.99"];
    upsWorldwide.label = @"UPS Worldwide Express";
    upsWorldwide.detail = @"Arrives in 1-3 days";
    upsWorldwide.identifier = @"ups_worldwide";
    PKShippingMethod *fedEx = [[PKShippingMethod alloc] init];
    fedEx.amount = [NSDecimalNumber decimalNumberWithString:@"5.99"];
    fedEx.label = @"FedEx";
    fedEx.detail = @"Arrives tomorrow";
    fedEx.identifier = @"fedex";

    if (address.country == nil || [address.country isEqualToString:@"US"]) {
        completion(STPShippingStatusInvalid, nil, nil, nil);
    } else {
        completion(STPShippingStatusValid, nil, @[upsGround, upsWorldwide, fedEx], fedEx);
    }
}

- (void)shippingAddressViewController:(__unused STPShippingAddressViewController *)addressViewController
                 didFinishWithAddress:(__unused STPAddress *)address
                       shippingMethod:(nullable __unused PKShippingMethod *)method {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end

