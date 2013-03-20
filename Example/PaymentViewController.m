//
//  PaymentViewController.m
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PaymentViewController.h"
#import "MBProgressHUD.h"
#define STRIPE_PUBLISHABLE_KEY @"pk_test_czwzkTp2tactuLOEOqbMTRzG"

@interface PaymentViewController ()
- (void)hasError:(NSError *)error;
- (void)hasToken:(STPToken *)token;
@end

@implementation PaymentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Add Card";
    
    // Setup save button
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:0 target:self action:@selector(save:)];
    saveButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Setup checkout
    self.checkoutView = [[STPView alloc] initWithFrame:CGRectMake(15,20,290,55) andKey:STRIPE_PUBLISHABLE_KEY];
    self.checkoutView.delegate = self;
    [self.view addSubview:self.checkoutView];
}

- (void)stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid
{
    // Enable save button if the Checkout is valid
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

- (IBAction)save:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self.checkoutView createToken:^(STPToken *token, NSError *error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
        if (error) {
            [self hasError:error];
        } else {
            [self hasToken:token];
        }
    }];
}

- (void)hasError:(NSError *)error
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                      message:[error localizedDescription]
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    [message show];
}

- (void)hasToken:(STPToken *)token
{
    NSLog(@"Received token %@", token.tokenId);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://example.com"]];
    request.HTTPMethod = @"POST";
    NSString *body     = [NSString stringWithFormat:@"stripeToken=%@", token.tokenId];
    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [MBProgressHUD hideHUDForView:self.view animated:YES];
                               
//                               if (error) {
//                                   [self hasError:error];
//                               } else {
                                   [self.navigationController popViewControllerAnimated:YES];
//                               }
                           }];
}

@end
