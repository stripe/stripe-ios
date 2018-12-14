//
//  MasterViewController.m
//  LocalizationTests
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"

#import "STP"

typedef NS_ENUM(NSInteger, LocalizedScreen) {
    LocalizedScreenPaymentCardTextField = 0,
    LocalizedScreenAddCardVCStandard,
    LocalizedScreenAddCardVCPrefilledShipping,
    LocalizedScreenAddCardPrefilledDelivery,
    LocalizedScreenPaymentMethodsVC,
    LocalizedScreenShippingAddressVC,
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
        case LocalizedScreenShippingAddressVC:
            return @"Shipping Info VC";
    }
}

@interface MasterViewController ()

@property NSArray<NSNumber *> *screenTypes;
@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.screenTypes = @[
                         @(LocalizedScreenPaymentCardTextField),
                         @(LocalizedScreenAddCardVCStandard),
                         @(LocalizedScreenAddCardVCPrefilledShipping),
                         @(LocalizedScreenAddCardPrefilledDelivery),
                         @(LocalizedScreenPaymentMethodsVC),
                         @(LocalizedScreenShippingAddressVC),
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.screenTypes.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    LocalizedScreen screenType = [self.screenTypes[indexPath.row] integerValue];

    cell.textLabel.text = TitleForLocalizedScreen(screenType);
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LocalizedScreen screenType = [self.screenTypes[indexPath.row] integerValue];
    UIViewController *vc = nil;
    switch (screen) {
        case LocalizedScreenPaymentCardTextField:
            vc = [[STPPaymentCardTextField alloc] init];
        case LocalizedScreenAddCardVCStandard:
            return @"Add Card VC Standard";
        case LocalizedScreenAddCardVCPrefilledShipping:
            return @"Add Card VC Prefilled Shipping";
        case LocalizedScreenAddCardPrefilledDelivery:
            return @"Add Card VC Prefilled Delivery";
        case LocalizedScreenPaymentMethodsVC:
            return @"Payment Methods VC";
        case LocalizedScreenShippingAddressVC:
            return @"Shipping Info VC";
    }
    [self.navigationController pushViewController:vc animated:NO];
}


@end
