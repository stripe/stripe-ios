//
//  BrowseExamplesViewController.m
//  Custom Integration
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "BrowseExamplesViewController.h"

#import "ApplePayExampleViewController.h"
#import "CardAutomaticConfirmationViewController.h"
#import "CardManualConfirmationExampleViewController.h"
#import "CardSetupIntentBackendExampleViewController.h"
#import "CardSetupIntentExampleViewController.h"
#import "Constants.h"
#import "SofortExampleViewController.h"
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
    return 7;
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
        }
    }
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - STPBackendCharging

- (void)_callOnMainThread:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

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
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a payment intent."}];
        [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
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
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultSuccess, json[@"secret"], nil); }];
                                                              }
                                                              else {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

- (void)createAndConfirmPaymentIntentWithAmount:(NSNumber *)amount
                                  paymentMethod:(NSString *)paymentMethodID
                                      returnURL:(NSString *)returnURL
                                     completion:(STPPaymentIntentCreateAndConfirmHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a payment intent."}];
        [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
        return;
    }

    // This passes the token off to our payment backend, which will then actually complete charging the card using your Stripe account's secret key
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"capture_payment"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:
                          @"payment_method=%@&amount=%@&return_url=%@",
                          paymentMethodID,
                          amount,
                          returnURL];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error) {
                                                              [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json && [json isKindOfClass:[NSDictionary class]]) {
                                                                  NSString *clientSecret = json[@"secret"];
                                                                  if (clientSecret != nil) {
                                                                      [self _callOnMainThread:^{ completion(STPBackendResultSuccess, clientSecret, nil); }];
                                                                  } else {
                                                                      [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, [NSError errorWithDomain:StripeDomain
                                                                                                                                                              code:STPAPIError
                                                                                                                                                          userInfo:@{NSLocalizedDescriptionKey: @"There was an error parsing your backend response to a client secret."}]); }];
                                                                  }
                                                              } else {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

- (void)confirmPaymentIntent:(STPPaymentIntent *)paymentIntent completion:(STPConfirmPaymentIntentCompletionHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to confirm a payment intent."}];
        [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
        return;
    }

    // This asks the backend to create a PaymentIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"confirm_payment"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:@"payment_intent_id=%@", paymentIntent.stripeId];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json && [json isKindOfClass:[NSDictionary class]]) {
                                                                  NSString *clientSecret = json[@"secret"];
                                                                  if (clientSecret != nil) {
                                                                      [self _callOnMainThread:^{ completion(STPBackendResultSuccess, clientSecret, nil); }];
                                                                  } else {
                                                                      [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, [NSError errorWithDomain:StripeDomain
                                                                                                                                                              code:STPAPIError
                                                                                                                                                          userInfo:@{NSLocalizedDescriptionKey: @"There was an error parsing your backend response to a client secret."}]); }];
                                                                  }
                                                              } else {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

- (void)createSetupIntentWithPaymentMethod:(NSString *)paymentMethodID
                                 returnURL:(NSString *)returnURL
                                completion:(STPCreateSetupIntentCompletionHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:StripeDomain
                                             code:STPInvalidRequestError
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to confirm a payment intent."}];
        [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
        return;
    }
    
    // This asks the backend to create a SetupIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_setup_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = @"";

    if (paymentMethodID != nil) {
        postBody = [postBody stringByAppendingString:[NSString stringWithFormat:@"payment_method=%@", paymentMethodID]];
    }
    if (returnURL != nil) {
        if (postBody.length > 0) {
            postBody = [postBody stringByAppendingString:@"&"];
        }
        postBody = [postBody stringByAppendingString:[NSString stringWithFormat:@"return_url=%@", returnURL]];
    }

    NSData *data = postBody.length > 0 ? [postBody dataUsingEncoding:NSUTF8StringEncoding] : [NSData data];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:StripeDomain
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, error); }];
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultSuccess, json[@"secret"], nil); }];
                                                              }
                                                              else {
                                                                  [self _callOnMainThread:^{ completion(STPBackendResultFailure, nil, jsonError); }];
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
