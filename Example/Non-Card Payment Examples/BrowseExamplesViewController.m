//
//  BrowseExamplesViewController.m
//  Non-Card Payment Examples
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

@import Stripe;
#import "Non_Card_Payment_Examples-Swift.h"

#import "BrowseExamplesViewController.h"

#import "ApplePayExampleViewController.h"
#import "AUBECSDebitExampleViewController.h"
#import "BancontactExampleViewController.h"
#import "FPXExampleViewController.h"
#import "GiropayExampleViewController.h"
#import "iDEALExampleViewController.h"
#import "Przelewy24ExampleViewController.h"
#import "OXXOExampleViewController.h"
#import "SEPADebitExampleViewController.h"
#import "SofortSourcesExampleViewController.h"
#import "SofortExampleViewController.h"
#import "WeChatPayExampleViewController.h"
#import "EPSExampleViewController.h"

/**
 This view controller presents different examples, each of which demonstrates creating a payment using a different payment method or integration.
 */
@interface BrowseExamplesViewController () <ExampleViewControllerDelegate>
@end

@implementation BrowseExamplesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Examples";
    self.navigationController.navigationBar.translucent = NO;
    self.tableView.tableFooterView = [UIView new];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 18;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Apple Pay";
            break;
        case 1:
            cell.textLabel.text = @"Sofort (Sources)";
            break;
        case 2:
            cell.textLabel.text = @"WeChat Pay (Sources)";
            break;
        case 3:
            cell.textLabel.text = @"FPX";
            break;
        case 4:
            cell.textLabel.text = @"SEPA Debit";
            break;
        case 5:
            cell.textLabel.text = @"iDEAL";
            break;
        case 6:
            cell.textLabel.text = @"Alipay";
            break;
        case 7:
            cell.textLabel.text = @"Klarna";
            break;
        case 8:
            cell.textLabel.text = @"Bacs Debit";
            break;
        case 9:
            cell.textLabel.text = @"AU BECS Debit";
            break;
        case 10:
            cell.textLabel.text = @"giropay";
            break;
        case 11:
            cell.textLabel.text = @"Przelewy24";
            break;
        case 12:
            cell.textLabel.text = @"Bancontact";
            break;
        case 13:
            cell.textLabel.text = @"EPS";
            break;
        case 14:
            cell.textLabel.text = @"Sofort (PaymentMethods)";
            break;
        case 15:
            cell.textLabel.text = @"GrabPay";
            break;
        case 16:
            cell.textLabel.text = @"OXXO";
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController;
    if ([StripeAPI defaultPublishableKey] == nil) {
        [self _displayAlert:@"Please set a Stripe Publishable Key in Constants.m" viewController:self completion:^{
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }];
        return;
    }

    switch (indexPath.row) {
        case 0: {
            ApplePayExampleViewController *exampleVC = [ApplePayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 1: {
            SofortSourcesExampleViewController *exampleVC = [SofortSourcesExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 2: {
            WeChatPayExampleViewController *exampleVC = [WeChatPayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 3: {
            FPXExampleViewController *exampleVC = [FPXExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 4: {
            SEPADebitExampleViewController *exampleVC = [SEPADebitExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 5: {
            iDEALExampleViewController *exampleVC = [iDEALExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 6: {
            AlipayExampleViewController *exampleVC = [AlipayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 7: {
            KlarnaExampleViewController *exampleVC = [KlarnaExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 8: {
            BacsDebitExampleViewController *exampleVC = [BacsDebitExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 9: {
            AUBECSDebitExampleViewController *exampleVC = [AUBECSDebitExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 10: {
            GiropayExampleViewController *exampleVC = [GiropayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 11: {
            Przelewy24ExampleViewController *exampleVC = [Przelewy24ExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 12: {
            BancontactExampleViewController *exampleVC = [BancontactExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 13: {
            EPSExampleViewController *exampleVC = [EPSExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 14: {
            SofortExampleViewController *exampleVC = [SofortExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 15: {
            GrabPayExampleViewController *exampleVC = [GrabPayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 16: {
            OXXOExampleViewController *exampleVC = [OXXOExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)_displayAlert:(NSString *)message viewController:(UIViewController *)viewController completion:(void (^)(void))completion {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        completion();
    }];
    [alertController addAction:action];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - ExampleViewControllerDelegate

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _displayAlert:message viewController:controller completion:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    });
}

- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@", error);
        [self _displayAlert:[error localizedDescription] viewController:self completion:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    });
}

#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self.navigationController.topViewController;
}

@end
