//
//  STPTestingAPIClient.m
//  StripeiOS
//
//  Created by Cameron Sabol on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPTestingAPIClient.h"
@import StripeCore;

static NSString * const STPTestingHostedBackendURL = @"https://stp-mobile-ci-test-backend-e1b3.stripedemos.com/";

static BOOL STPUsesHostedTestBackends = NO;

// The unified test backends' Vercel deployment answers only requests with its Protection Bypass for
// Automation secret, which is deliberately public. STRIPE_TEST_BACKENDS_BYPASS overrides it.
static NSString * const STPTestingDefaultTestBackendsBypass = @"PublicAvailableiOSAndroidBackend";

NS_ASSUME_NONNULL_BEGIN

@implementation STPTestingAPIClient

+ (nullable NSString *)testBackendsURL {
    if (STPUsesHostedTestBackends) {
        return nil;
    }
    NSString *url = NSProcessInfo.processInfo.environment[@"STRIPE_TEST_BACKENDS_URL"];
    if (url.length == 0) {
        return nil;
    }
    return [url hasSuffix:@"/"] ? url : [url stringByAppendingString:@"/"];
}

+ (NSDictionary<NSString *, NSString *> *)testBackendsHeaders {
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary dictionary];
    if (self.testBackendsURL == nil) {
        return headers;
    }
    NSDictionary<NSString *, NSString *> *environment = NSProcessInfo.processInfo.environment;
    NSString *token = environment[@"STRIPE_TEST_BACKENDS_TOKEN"];
    if (token.length > 0) {
        headers[@"X-Test-Backends-Token"] = token;
    }
    NSString *bypass = environment[@"STRIPE_TEST_BACKENDS_BYPASS"];
    if (bypass.length == 0) {
        // A local copy of the backends isn't behind Vercel.
        NSString *host = [NSURL URLWithString:self.testBackendsURL].host;
        BOOL isLocal = [@[@"127.0.0.1", @"localhost", @"::1"] containsObject:host.lowercaseString];
        bypass = isLocal ? nil : STPTestingDefaultTestBackendsBypass;
    }
    if (bypass.length > 0) {
        headers[@"x-vercel-protection-bypass"] = bypass;
    }
    return headers;
}

+ (BOOL)usesHostedTestBackends {
    return STPUsesHostedTestBackends;
}

+ (void)setUsesHostedTestBackends:(BOOL)usesHostedTestBackends {
    STPUsesHostedTestBackends = usesHostedTestBackends;
}

+ (NSString *)testBackendURLWithPrefix:(NSString *)prefix hostedURL:(NSString *)hostedURL {
    NSString *root = self.testBackendsURL;
    if (root == nil) {
        return hostedURL;
    }
    return [NSString stringWithFormat:@"%@%@/", root, prefix];
}

+ (NSString *)backendURL {
    return [self testBackendURLWithPrefix:@"ci-test-backend" hostedURL:STPTestingHostedBackendURL];
}

+ (instancetype)sharedClient {
    static dispatch_once_t onceToken;
    static STPTestingAPIClient *sharedClient = nil;
    dispatch_once(&onceToken, ^{
        sharedClient = [[STPTestingAPIClient alloc] init];
    });

    return sharedClient;
}

- (instancetype)init {
    self = [super init];
    self.sessionConfig = [[NSURLSession sharedSession] configuration];
    return self;
}

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self createPaymentIntentWithParams:params
                                account:nil
                             completion:completion];
}

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self createPaymentIntentWithParams:params
                                account:account
                             apiVersion:nil
                             completion:completion];
}

- (void)createPaymentIntentWithParams:(nullable NSDictionary *)params
                              account:(nullable NSString *)account
                           apiVersion:(nullable NSString *)apiVersion
                           completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfig];
    NSURL *url = [NSURL URLWithString:[[STPTestingAPIClient backendURL] stringByAppendingString:@"create_payment_intent"]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [STPTestingAPIClient.testBackendsHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, __unused BOOL *stop) {
        [request setValue:value forHTTPHeaderField:field];
    }];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:@{@"account" : account ?: @"",
                                                                 @"create_params": params ?: @{},
                                                                 @"version": apiVersion ?: STPAPIClient.apiVersion,
                                                               } options:0 error:NULL];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:postData
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          if (error) {
                                                              completion(nil, error);
                                                          } else if (data == nil || httpResponse.statusCode != 200) {
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  NSString *errorStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                                  NSDictionary *userInfo = @{
                                                                      STPError.errorMessageKey: errorStr,
                                                                      NSLocalizedDescriptionKey: errorStr
                                                                  };
                                                                  NSError *apiError = [NSError errorWithDomain:STPError.stripeDomain code:STPAPIError userInfo:userInfo];
                                                                  NSLog(@"%@", apiError);
                                                                  completion(nil, apiError);
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
    [self createSetupIntentWithParams:params
                              account:nil
                           completion:completion];
}

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account
                         completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    [self createSetupIntentWithParams:params
                              account:account
                           apiVersion:nil
                           completion:completion];
}

- (void)createSetupIntentWithParams:(nullable NSDictionary *)params
                            account:(nullable NSString *)account
                         apiVersion:(nullable NSString *)apiVersion
                         completion:(void (^)(NSString *_Nullable, NSError * _Nullable))completion {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfig];
    NSURL *url = [NSURL URLWithString:[[STPTestingAPIClient backendURL] stringByAppendingString:@"create_setup_intent"]];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [STPTestingAPIClient.testBackendsHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, __unused BOOL *stop) {
        [request setValue:value forHTTPHeaderField:field];
    }];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:@{@"account" : account ?: @"",
                                                                 @"create_params": params ?: @{},
                                                                 @"version": apiVersion ?: STPAPIClient.apiVersion,
                                                               } options:0 error:NULL];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:postData
                                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (error) {
            completion(nil, error);
        } else if (data == nil || httpResponse.statusCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary *userInfo = @{
                    STPError.errorMessageKey: errorStr,
                    NSLocalizedDescriptionKey: errorStr
                };
                NSError *apiError = [NSError errorWithDomain:STPError.stripeDomain code:STPAPIError userInfo:userInfo];
                NSLog(@"%@", apiError);
                completion(nil, apiError);
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
