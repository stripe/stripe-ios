//
//  BrowseExamplesViewController.m
//  Stripe iOS Example (Custom)
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "BrowseExamplesViewController.h"
#import "ApplePayExampleViewController.h"
#import "CardExampleViewController.h"
#import "Constants.h"
#import "SofortExampleViewController.h"
#import "ThreeDSExampleViewController.h"

/**
 This view controller presents different examples, each of which demonstrates creating a payment using a different payment method.
 If the example creates a chargeable source or a token, `createBackendChargeWithSource:completion:` will be called to tell our
 example backend to create the charge request.
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
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Card";
            break;
        case 1:
            cell.textLabel.text = @"Card + 3DS";
            break;
        case 2:
            cell.textLabel.text = @"Apple Pay";
            break;
        case 3:
            cell.textLabel.text = @"Sofort";
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *viewController;
    switch (indexPath.row) {
        case 0: {
            CardExampleViewController *exampleVC = [CardExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 1: {
            ThreeDSExampleViewController *exampleVC = [ThreeDSExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 2: {
            ApplePayExampleViewController *exampleVC = [ApplePayExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
        case 3: {
            SofortExampleViewController *exampleVC = [SofortExampleViewController new];
            exampleVC.delegate = self;
            viewController = exampleVC;
            break;
        }
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - STPBackendCharging

- (void)createBackendChargeWithSource:(NSString *)sourceID completion:(STPSourceSubmissionHandler)completion {
    // In your app, you should send the source's id to your backend,
    // along with any information necessary to fulfill your customer's order.
    // On your backend, once you've fulfilled your customer's order, you can
    // complete the payment by charging the source using your Stripe account's
    // secret key.
    // https://stripe.com/docs/api#create_charge
    completion(STPBackendChargeResultSuccess)
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
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:action];
        [controller presentViewController:alertController animated:YES completion:nil];
    });
}

@end
