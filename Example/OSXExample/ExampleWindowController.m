//
//  ExampleWindowController.m
//  OSXExample
//
//  Created by Jack Flintermann on 12/17/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "Stripe.h"
#import "ExampleWindowController.h"

@interface ExampleWindowController () <STPCheckoutViewControllerDelegate>
@property STPCheckoutViewController *checkoutController;
@end

@implementation ExampleWindowController

- (IBAction)beginPayment:(id)sender {
    STPCheckoutOptions *options = [STPCheckoutOptions new];
    options.publishableKey = @"pk_test_09IUAkhSGIz8mQP3prdgKm06";
    options.appleMerchantId = @"<#Replace me with your Apple Merchant ID #>";
    options.purchaseDescription = @"Tasty Llama food";
    options.purchaseAmount = @1000;
    options.purchaseLabel = @"Pay {{amount}} for that food";
    options.enablePostalCode = @YES;
    options.logoColor = [NSColor purpleColor];

    self.checkoutController = [[STPCheckoutViewController alloc] initWithOptions:options];
    self.checkoutController.checkoutDelegate = self;
    NSView *webView = self.checkoutController.view;
    [self.window.contentView addSubview:webView];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                                    options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                    metrics:nil
                                                                                      views:NSDictionaryOfVariableBindings(webView)]];
    [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                                    options:NSLayoutFormatDirectionLeadingToTrailing
                                                                                    metrics:nil
                                                                                      views:NSDictionaryOfVariableBindings(webView)]];
    [self.window.contentViewController addChildViewController:self.checkoutController];
}

- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    completion(STPBackendChargeResultSuccess, nil);
}

- (void)checkoutController:(STPCheckoutViewController *)controller didFailWithError:(NSError *)error {
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller {
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

- (void)checkoutControllerDidFinish:(STPCheckoutViewController *)controller {
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
}

@end
