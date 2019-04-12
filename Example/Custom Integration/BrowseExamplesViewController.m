//
//  BrowseExamplesViewController.m
//  Custom Integration (ObjC)
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "BrowseExamplesViewController.h"

#import "ApplePayExampleViewController.h"
#import "CardExampleViewController.h"
#import "CardManualIntegrationExampleViewController.h"
#import "Constants.h"
#import "SofortExampleViewController.h"

/**
 This view controller presents different examples, each of which demonstrates creating a payment using a different payment method or integration.
 */
@interface BrowseExamplesViewController () <ExampleViewControllerDelegate>
@end

@implementation BrowseExamplesViewController {
    STPRedirectContext *_redirectContext;
}

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
            cell.textLabel.text = @"Card w/ Manual Integration";
            break;
        case 2:
            cell.textLabel.text = @"Apple Pay";
            break;
        case 3:
            cell.textLabel.text = @"Sofort (Sources)";
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
            CardManualIntegrationExampleViewController *exampleVC = [CardManualIntegrationExampleViewController new];
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

/**
 Ask the example backend to create a PaymentIntent with the specified amount.

 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.

 @param amount Amount to charge the customer
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)createBackendPaymentIntentWithAmount:(NSNumber *)amount completion:(STPPaymentIntentCreationHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a charge."}];
        completion(STPBackendResultFailure, nil, error);
        return;
    }

    // This asks the backend to create a PaymentIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:
                          @"amount=%@&metadata[charge_request_id]=%@",
                          amount,
                          // example-ios-backend allows passing metadata through to Stripe
                          @"B3E611D1-5FA1-4410-9CEC-00958A5126CB"
                          ];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: @"There was an error connecting to your payment backend."}];
                                                          }
                                                          if (error || data == nil) {
                                                              completion(STPBackendResultFailure, nil, error);
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  completion(STPBackendResultSuccess, json[@"secret"], nil);
                                                              }
                                                              else {
                                                                  completion(STPBackendResultFailure, nil, jsonError);
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

- (void)createAndConfirmPaymentIntentWithAmount:(NSNumber *)amount
                                  paymentMethod:(NSString *)paymentMethodID
                                     completion:(STPPaymentIntentCreateAndConfirmHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a payment intent."}];
        completion(STPBackendResultFailure, nil, error);
        return;
    }

    // This passes the token off to our payment backend, which will then actually complete charging the card using your Stripe account's secret key
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_charge"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:
                          @"payment_method=%@&amount=%@&metadata[charge_request_id]=%@",
                          paymentMethodID,
                          @1099,
                          // example-ios-backend allows passing metadata through to Stripe
                          @"B3E611D1-5FA1-4410-9CEC-00958A5126CB"];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: @"There was an error connecting to your payment backend."}];
                                                          }
                                                          if (error) {
                                                              completion(STPBackendResultFailure, nil, error);
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  completion(STPBackendResultSuccess, json[@"secret"], nil);
                                                              }
                                                              else {
                                                                  completion(STPBackendResultFailure, nil, jsonError);
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
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

- (void)performRedirectForViewController:(UIViewController *)controller
                       withPaymentIntent:(STPPaymentIntent *)paymentIntent
                              completion:(STPRedirectCompletionHandler)completion {
    if (_redirectContext != nil) {
        completion(nil,[NSError errorWithDomain:StripeDomain
                                           code:STPInvalidRequestError
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ should not have multiple concurrent redirects.", NSStringFromClass([self class])]}]);
        return;
    }
    __weak __typeof(self) weakSelf = self;
    STPRedirectContext *redirectContext = [[STPRedirectContext alloc] initWithPaymentIntent:paymentIntent completion:^(NSString * _Nonnull clientSecret, NSError * _Nullable error) {
        completion(clientSecret, error);
        __typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            strongSelf->_redirectContext = nil;
        }
    }];

    if (redirectContext) {
        _redirectContext = redirectContext;
        [redirectContext startRedirectFlowFromViewController:controller];
    } else {
        completion(nil,[NSError errorWithDomain:StripeDomain
                                           code:STPInvalidRequestError
                                       userInfo:@{NSLocalizedDescriptionKey: @"Internal error creating redirect context."}]);
    }
}

@end
