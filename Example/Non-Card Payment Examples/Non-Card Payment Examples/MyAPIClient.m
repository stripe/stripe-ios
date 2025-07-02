//
//  ExampleAPIClient.m
//  Non-Card Payment Examples
//
//  Created by Yuki Tokuhiro on 9/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//
@import Stripe;
@import StripeCore;

#import "MyAPIClient.h"

#import "Constants.h"

@implementation MyAPIClient

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (void)_callOnMainThread:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

#pragma mark - PaymentIntents (automatic confirmation)

/**
 Ask the example backend to create a PaymentIntent with the specified amount.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.
 
 @param additionalParameters additional parameters to pass to the example backend
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)createPaymentIntentWithCompletion:(STPPaymentIntentCreationHandler)completion additionalParameters:(NSString *)additionalParameters {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a payment intent."}];
        [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
        return;
    }
    
    // This asks the backend to create a PaymentIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_payment_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:
                          @"metadata[charge_request_id]=%@",
                          // example-mobile-backend allows passing metadata through to Stripe
                          @"B3E611D1-5FA1-4410-9CEC-00958A5126CB"
                          ];
    if (additionalParameters != nil) {
        postBody = [postBody stringByAppendingFormat:@"&%@", additionalParameters];
    }
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, json[@"secret"], nil); }];
                                                              }
                                                              else {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];
    
    [uploadTask resume];
}

#pragma mark - PaymentIntents (manual confirmation)

- (void)createAndConfirmPaymentIntentWithPaymentMethod:(NSString *)paymentMethodID
                                             returnURL:(NSString *)returnURL
                                            completion:(STPPaymentIntentCreateAndConfirmHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to create a payment intent."}];
        [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, NO, nil, error); }];
        return;
    }
    
    // This passes the token off to our payment backend, which will then actually complete charging the card using your Stripe account's secret key
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"confirm_payment_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:
                          @"payment_method_id=%@&return_url=%@",
                          paymentMethodID,
                          returnURL];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                          code:0
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error) {
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, NO, nil, error); }];
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json && [json isKindOfClass:[NSDictionary class]]) {
                                                                  if (json[@"success"]) {
                                                                      [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, NO, nil, nil); }];
                                                                      return;
                                                                  } else if (json[@"secret"]) {
                                                                      NSString *clientSecret = json[@"secret"];
                                                                      [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, YES, clientSecret, nil); }];
                                                                      return;
                                                                  }
                                                              }
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, NO, nil, [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                                                                                           code:0
                                                                                                                                                       userInfo:@{NSLocalizedDescriptionKey: @"There was an error parsing your backend response to a client secret."}]); }];
                                                          }
                                                      }];
    
    [uploadTask resume];
}

- (void)confirmPaymentIntent:(NSString *)paymentIntentID completion:(STPConfirmPaymentIntentCompletionHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to confirm a payment intent."}];
        [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, error); }];
        return;
    }
    
    // This asks the backend to create a PaymentIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"confirm_payment_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:@"payment_intent_id=%@", paymentIntentID];
    NSData *data = [postBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                          code:0
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, error); }];
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json && [json isKindOfClass:[NSDictionary class]]) {
                                                                  NSNumber *success = json[@"success"];
                                                                  if ([success boolValue]) {
                                                                      [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, nil); }];
                                                                  } else {
                                                                      [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                                                                                              code:0
                                                                                                                                                          userInfo:@{NSLocalizedDescriptionKey: @"There was an error parsing your backend response to a client secret."}]); }];
                                                                  }
                                                              } else {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, jsonError); }];
                                                              }
                                                          }
                                                      }];
    
    [uploadTask resume];
}

#pragma mark - SetupIntents

- (void)createSetupIntentWithCompletion:(STPCreateSetupIntentCompletionHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to confirm a payment intent."}];
        [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
        return;
    }
    
    // This asks the backend to create a SetupIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_setup_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:[NSData data]
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, json[@"secret"], nil); }];
                                                              }
                                                              else {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];
    
    [uploadTask resume];
}

- (void)createAndConfirmSetupIntentWithPaymentMethod:(NSString *)paymentMethodID
                                           returnURL:(NSString *)returnURL
                                          completion:(STPCreateSetupIntentCompletionHandler)completion {
    if (!BackendBaseURL) {
        NSError *error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"You must set a backend base URL in Constants.m to confirm a payment intent."}];
        [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
        return;
    }
    
    // This asks the backend to create a SetupIntent for us, which can then be passed to the Stripe SDK to confirm
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSString *urlString = [BackendBaseURL stringByAppendingPathComponent:@"create_setup_intent"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSString *postBody = [NSString stringWithFormat:@"payment_method=%@&return_url=%@", paymentMethodID, returnURL];
    
    NSData *data = postBody.length > 0 ? [postBody dataUsingEncoding:NSUTF8StringEncoding] : [NSData data];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (!error && httpResponse.statusCode != 200) {
                                                              NSString *errorMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"There was an error connecting to your payment backend.";
                                                              error = [NSError errorWithDomain:@"MyAPIClientErrorDomain"
                                                                                          code:STPInvalidRequestError
                                                                                      userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                                                          }
                                                          if (error || data == nil) {
                                                              [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, error); }];
                                                          }
                                                          else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                                              
                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultSuccess, json[@"secret"], nil); }];
                                                              }
                                                              else {
                                                                  [self _callOnMainThread:^{ completion(MyAPIClientResultFailure, nil, jsonError); }];
                                                              }
                                                          }
                                                      }];
    
    [uploadTask resume];
}

@end
