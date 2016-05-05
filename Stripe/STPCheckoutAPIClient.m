//
//  STPCheckoutAPIClient.m
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCheckoutAPIClient.h"
#import "STPCheckoutBootstrapResponse.h"
#import "NSMutableURLRequest+Stripe.h"

@interface STPCheckoutAPIClient()
@property(nonatomic, copy)NSString *publishableKey;
@property(nonatomic)NSURLSession *accountSession;
@end

static NSString *CheckoutBaseURLString = @"https://checkout.stripe.com/api";

@implementation STPCheckoutAPIClient

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        _publishableKey = publishableKey;
        _bootstrapPromise = [STPVoidPromise new];
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"bootstrap"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSDictionary *payload = @{
                                  @"key": _publishableKey
                                  };
        __weak typeof(self) weakself = self;
        [request stp_addParametersToURL:payload];
        [[urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse * response, NSError *error) {
            if (error) {
                [weakself.bootstrapPromise fail:error];
            } else {
                STPCheckoutBootstrapResponse *bootstrap = [STPCheckoutBootstrapResponse bootstrapResponseWithData:data URLResponse:response];
                if (bootstrap && !bootstrap.accountsDisabled) {
                    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                    configuration.HTTPAdditionalHeaders = @{
                                                            @"X-Rack-Session": bootstrap.sessionID,
                                                            @"Stripe-Checkout-Test-Session": bootstrap.sessionID,
                                                            @"X-CSRF-Token": bootstrap.csrfToken,
                                                            };
                    weakself.accountSession = [NSURLSession sessionWithConfiguration:configuration];
                    [weakself.bootstrapPromise succeed];
                } else {
                    [weakself.bootstrapPromise fail:[NSError new]]; // TODO better error
                }
            }
        }] resume];
    }
    return self;
}

- (void)lookupEmail:(NSString *)email
         completion:(STPCheckoutLookupBlock)completion {
    __weak typeof(self) weakself = self;
    [[[self.bootstrapPromise voidFlatMap:^STPPromise*() {
        STPPromise<STPCheckoutAccountLookup *> *lookupPromise = [STPPromise<STPCheckoutAccountLookup *> new];
        if (!weakself) {
            [lookupPromise fail:[NSError new]]; // TODO better error
            return lookupPromise;
        }
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account/lookup"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  @"email": email,
                                  };
        [request stp_addParametersToURL:payload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [lookupPromise fail:[NSError new]]; // TODO better error
            }
            STPCheckoutAccountLookup *lookup = [STPCheckoutAccountLookup lookupWithData:data URLResponse:response];
            if (lookup) {
                [lookupPromise succeed:lookup];
            } else {
                [lookupPromise fail:[NSError new]]; // TODO better error
            }
        }] resume];
        return lookupPromise;
    }] onFailure:^(NSError * _Nonnull error) {
        completion(nil, error);
    }] onSuccess:^(STPCheckoutAccountLookup *lookup) {
        completion(lookup, nil);
    }];
}

- (void)sendSMSToAccountWithEmail:(NSString *)email
                       completion:(STPCheckoutVerificationBlock)completion {
    __weak typeof(self) weakself = self;
    [[[self.bootstrapPromise voidFlatMap:^STPPromise *{
        STPPromise *smsPromise = [STPPromise new];
        if (!weakself) {
            [smsPromise fail:[NSError new]]; // TODO better error
            return smsPromise;
        }
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account/verifications"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  @"email": email,
                                  @"merchant_name": @"Test",
                                  @"locale": @"en",
                                  };
        [request stp_addParametersToURL:payload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [smsPromise fail:error];
            }
            STPCheckoutAPIVerification *verification = [STPCheckoutAPIVerification verificationWithData:data URLResponse:response];
            if (verification) {
                [smsPromise succeed:verification];
            } else {
                [smsPromise fail:[NSError new]]; // TODO better error
            }
        }] resume];
        return smsPromise;
    }] onSuccess:^(__unused STPCheckoutAPIVerification *verification) {
        completion(verification, nil);
    }] onFailure:^(NSError *error) {
        completion(nil, error);
    }];
}

- (void)submitSMSCode:(NSString *)code
      forVerification:(STPCheckoutAPIVerification *)verification
           completion:(STPCheckoutAccountBlock)completion {
    __weak typeof(self) weakself = self;
    [[[self.bootstrapPromise voidFlatMap:^STPPromise *{
        STPPromise<STPCheckoutAccount*> *accountPromise = [STPPromise<STPCheckoutAccount *> new];
        if (!weakself) {
            [accountPromise fail:[NSError new]]; // TODO better error
            return accountPromise;
        }
        NSString *pathComponent = [@"account/verifications" stringByAppendingPathComponent:verification.verificationID];
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:pathComponent];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"PUT";
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  @"code": code,
                                  @"locale": @"en",
                                  };
        [request stp_addParametersToURL:payload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [accountPromise fail:error];
            }
            STPCheckoutAccount *account = [STPCheckoutAccount accountWithData:data URLResponse:response];
            if (account) {
                [accountPromise succeed:account];
            } else {
                [accountPromise fail:[NSError new]]; // TODO better error
            }
        }] resume];
        return accountPromise;
    }] onSuccess:^(STPCheckoutAccount *value) {
        completion(value, nil);
    }] onFailure:^(NSError *error) {
        completion(nil, error);
    }];
}

@end
