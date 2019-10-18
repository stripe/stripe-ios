//
//  BrowseExamplesViewController.m
//  Custom Integration
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "Custom_Integration-Swift.h"

#import "BrowseExamplesViewController.h"

#import "ApplePayExampleViewController.h"
#import "CardAutomaticConfirmationViewController.h"
#import "CardManualConfirmationExampleViewController.h"
#import "CardSetupIntentBackendExampleViewController.h"
#import "CardSetupIntentExampleViewController.h"
#import "iDEALExampleViewController.h"
#import "SofortExampleViewController.h"
#import "FPXExampleViewController.h"
#import "SEPADebitExampleViewController.h"
#import "WeChatPayExampleViewController.h"

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
    return 11;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Card (Automatic Confirmation)";
            break;
        case 1:
            cell.textLabel.text = @"Card (Manual Confirmation)";
            break;
        case 2:
            cell.textLabel.text = @"Card (SetupIntent)";
            break;
        case 3:
            cell.textLabel.text = @"Card (SetupIntent Backend Confirm)";
            break;
        case 4:
            cell.textLabel.text = @"Apple Pay";
            break;
        case 5:
            cell.textLabel.text = @"Sofort (Sources)";
            break;
        case 6:
            cell.textLabel.text = @"WeChat Pay (Sources)";
            break;
        case 7:
            cell.textLabel.text = @"FPX";
            break;
        case 8:
            cell.textLabel.text = @"SEPA Debit";
            break;
        case 9:
            cell.textLabel.text = @"iDEAL";
            break;
        case 10:
            cell.textLabel.text = @"Alipay";
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController;
    switch (indexPath.row) {
        case 0: {
            CardAutomaticConfirmationViewController *exampleVC = [CardAutomaticConfirmationViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 1: {
            CardManualConfirmationExampleViewController *exampleVC = [CardManualConfirmationExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 2: {
            CardSetupIntentExampleViewController *exampleVC = [CardSetupIntentExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 3: {
            CardSetupIntentBackendExampleViewController *exampleVC = [CardSetupIntentBackendExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 4: {
            ApplePayExampleViewController *exampleVC = [ApplePayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 5: {
            SofortExampleViewController *exampleVC = [SofortExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 6: {
            WeChatPayExampleViewController *exampleVC = [WeChatPayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 7: {
            FPXExampleViewController *exampleVC = [FPXExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 8: {
            SEPADebitExampleViewController *exampleVC = [SEPADebitExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 9: {
            iDEALExampleViewController *exampleVC = [iDEALExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 10: {
            AlipayExampleViewController *exampleVC = [AlipayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - ExampleViewControllerDelegate

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:action];
        [controller presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@", error);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:action];
        [controller presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self.navigationController.topViewController;
}

@end
