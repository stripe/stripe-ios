//
//  STPTestingAPIClient.m
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPTestingAPIClient.h"

#define STPTestingBackendURL @"https://floating-citadel-20318.herokuapp.com/"

NS_ASSUME_NONNULL_BEGIN

@implementation STPTestingAPIClient

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    static STPTestingAPIClient *sharedClient = nil;
    dispatch_once(&onceToken, ^{
        sharedClient = [[STPTestingAPIClient alloc] init];
    });

    return sharedClient;
}

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:[STPTestingBackendURL stringByAppendingString:@"create_payment_intent"]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:@{@"create_params": params ?: @{}} options:0 error:NULL];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:postData
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

                                                          if (error || data == nil || httpResponse.statusCode != 200) {
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  completion(nil, error);
                                                              });
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      completion(json[@"secret"], nil);
                                                                  });
                                                              } else {
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      completion(nil, jsonError);
                                                                  });
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                         completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:[STPTestingBackendURL stringByAppendingString:@"create_setup_intent"]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:@{@"create_params": params ?: @{}} options:0 error:NULL];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:postData
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

                                                          if (error || data == nil || httpResponse.statusCode != 200) {
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  completion(nil, error);
                                                              });
                                                          } else {
                                                              NSError *jsonError = nil;
                                                              id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

                                                              if (json &&
                                                                  [json isKindOfClass:[NSDictionary class]] &&
                                                                  [json[@"secret"] isKindOfClass:[NSString class]]) {
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      completion(json[@"secret"], nil);
                                                                  });
                                                              } else {
                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                      completion(nil, jsonError);
                                                                  });
                                                              }
                                                          }
                                                      }];

    [uploadTask resume];
}

@end

NS_ASSUME_NONNULL_END
