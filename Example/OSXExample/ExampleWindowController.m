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
@property (weak) IBOutlet NSButton *buyButton;
@end

@implementation ExampleWindowController

- (IBAction)beginPayment:(id)sender {
    STPCheckoutOptions *options = [STPCheckoutOptions new];
    options.publishableKey = [Stripe defaultPublishableKey];
    options.purchaseDescription = @"Tasty Llama food";
    options.purchaseAmount = 1000;
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
    self.buyButton.enabled = NO;
}

- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    self.buyButton.enabled = YES;
    // Todo: post the token to our server and make a charge
    completion(STPBackendChargeResultSuccess, nil);
}

- (void)checkoutController:(STPCheckoutViewController *)controller didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    self.buyButton.enabled = YES;
    [controller.view removeFromSuperview];
    if (status == STPPaymentStatusSuccess) {
        // yay!
    }
}

@end
