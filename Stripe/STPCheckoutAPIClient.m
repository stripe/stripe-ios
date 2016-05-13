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
#import "STPFormEncoder.h"
#import "STPAPIClient.h"
#import "STPCardValidator.h"
#import "NSBundle+Stripe_AppName.h"
#import "StripeError.h"

@interface STPCheckoutAPIClient()
@property(nonatomic, copy)NSString *publishableKey;
@property(nonatomic)NSURLSession *accountSession;
@property(nonatomic)STPAPIClient *tokenClient;
@end

static NSString *CheckoutBaseURLString = @"https://qa-checkout.stripe.com/api"; // TODO

@implementation STPCheckoutAPIClient

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        _publishableKey = publishableKey;
        _merchantName = [NSBundle stp_applicationName];
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
            __strong typeof(weakself) strongself = weakself;
            if (error) {
                [strongself.bootstrapPromise fail:error];
            } else {
                STPCheckoutBootstrapResponse *bootstrap = [STPCheckoutBootstrapResponse bootstrapResponseWithData:data URLResponse:response];
                if (bootstrap && !bootstrap.accountsDisabled) {
                    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
                    configuration.HTTPAdditionalHeaders = @{
                                                            @"X-Rack-Session": bootstrap.sessionID,
                                                            @"Stripe-Checkout-Test-Session": bootstrap.sessionID,
                                                            @"X-CSRF-Token": bootstrap.csrfToken,
                                                            };
                    strongself.accountSession = [NSURLSession sessionWithConfiguration:configuration];
                    strongself.tokenClient = bootstrap.tokenClient;
                    [strongself.bootstrapPromise succeed];
                } else {
                    [strongself.bootstrapPromise fail:[strongself.class genericRememberMeErrorWithResponseData:data message:@"Bootstrap failed."]];
                }
            }
        }] resume];
    }
    return self;
}

- (BOOL)readyForLookups {
    return self.bootstrapPromise.completed && !self.bootstrapPromise.error;
}

- (STPPromise *)lookupEmail:(NSString *)email {
    __weak typeof(self) weakself = self;
    return [self.bootstrapPromise voidFlatMap:^STPPromise*() {
        __strong typeof(weakself) strongself = weakself;
        if (!strongself) {
            return [STPPromise promiseWithError:[STPCheckoutAPIClient cancellationError]];
        }
        STPPromise<STPCheckoutAccountLookup *> *lookupPromise = [STPPromise<STPCheckoutAccountLookup *> new];
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account/lookup"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  @"email": email,
                                  };
        [request stp_addParametersToURL:payload];
        [[strongself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            STPCheckoutAccountLookup *lookup = [STPCheckoutAccountLookup lookupWithData:data URLResponse:response];
            if (lookup) {
                [lookupPromise succeed:lookup];
            } else {
                [lookupPromise fail:error ?: [strongself.class genericRememberMeErrorWithResponseData:data message:@"Failed to parse account lookup response"]];
            }
        }] resume];
        return lookupPromise;
    }];
}

- (STPPromise *)sendSMSToAccountWithEmail:(NSString *)email {
    __weak typeof(self) weakself = self;
    return [self.bootstrapPromise voidFlatMap:^STPPromise *{
        __strong typeof(weakself) strongself = weakself;
        STPPromise *smsPromise = [STPPromise new];
        if (!strongself) {
            return [STPPromise promiseWithError:[STPCheckoutAPIClient cancellationError]];
        }
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account/verifications"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  @"email": email,
                                  @"locale": @"en",
                                  };
        NSDictionary *formPayload = @{
                                      @"merchant_name": self.merchantName,
                                      };
        [request stp_addParametersToURL:payload];
        [request stp_setFormPayload:formPayload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            STPCheckoutAPIVerification *verification = [STPCheckoutAPIVerification verificationWithData:data URLResponse:response];
            if (verification) {
                [smsPromise succeed:verification];
            } else {
                [smsPromise fail:error ?: [strongself.class genericRememberMeErrorWithResponseData:data message:@"Failed to parse SMS verification"]];
            }
        }] resume];
        return smsPromise;
    }];
}

- (STPPromise *)submitSMSCode:(NSString *)code
              forVerification:(STPCheckoutAPIVerification *)verification {
    __weak typeof(self) weakself = self;
    return [self.bootstrapPromise voidFlatMap:^STPPromise *{
        __strong typeof(weakself) strongself = weakself;
        STPPromise<STPCheckoutAccount*> *accountPromise = [STPPromise<STPCheckoutAccount *> new];
        if (!strongself) {
            return [STPPromise promiseWithError:[STPCheckoutAPIClient cancellationError]];
        }
        NSString *pathComponent = [@"account/verifications" stringByAppendingPathComponent:verification.verificationID];
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:pathComponent];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"PUT";

        NSDictionary *formPayload = @{
                                      @"code": code,
                                      @"key": weakself.publishableKey,
                                      @"locale": @"en",
                                      };
        [request stp_setFormPayload:formPayload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            STPCheckoutAccount *account = [STPCheckoutAccount accountWithData:data URLResponse:response];
            if (account) {
                [accountPromise succeed:account];
            } else {
                [accountPromise fail:error ?: [strongself.class genericRememberMeErrorWithResponseData:data message:@"Failed to parse checkout account response"]];
            }
        }] resume];
        return accountPromise;
    }];
}

- (STPPromise *)createTokenWithAccount:(STPCheckoutAccount *)account {
    __weak typeof(self) weakself = self;
    return [self.bootstrapPromise voidFlatMap:^STPPromise *{
        __strong typeof(weakself) strongself = weakself;
        STPPromise<STPToken *> *tokenPromise = [STPPromise new];
        if (!strongself) {
            return [STPPromise promiseWithError:[STPCheckoutAPIClient cancellationError]];
        }
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account/tokens"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        NSDictionary *payload = @{
                                  @"key": weakself.publishableKey,
                                  };
        [request stp_addParametersToURL:payload];
        [request setValue:account.sessionID forHTTPHeaderField:@"X-Rack-Session"];
        [request setValue:account.sessionID forHTTPHeaderField:@"Stripe-Checkout-Test-Session"];
        [request setValue:account.csrfToken forHTTPHeaderField:@"X-CSRF-Token"];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(__unused NSData *data, __unused NSURLResponse *response, NSError *error) {
            STPToken *token = [self parseTokenFromResponse:response data:data];
            if (token) {
                [tokenPromise succeed:token];
            } else {
                [tokenPromise fail:error ?: [strongself.class genericRememberMeErrorWithResponseData:data message:@"Failed to parse token from checkout response"]];
            }
        }] resume];
        return tokenPromise;
    }];
}

- (STPPromise *)createAccountWithCardParams:(STPCardParams *)cardParams
                                      email:(NSString *)email
                                      phone:(NSString *)phone {
    __weak typeof(self) weakself = self;
    return [[self.bootstrapPromise voidFlatMap:^STPPromise * _Nonnull{
        STPPromise *tokenPromise = [STPPromise new];
        [self.tokenClient createTokenWithCard:cardParams completion:^(STPToken *token, NSError *error) {
            if (error) {
                [tokenPromise fail:error];
            } else {
                [tokenPromise succeed:token];
            }
        }];
        return tokenPromise;
    }] flatMap:^STPPromise *(STPToken *token) {
        __strong typeof(self) strongself = weakself;
        if (!strongself) {
            return [STPPromise promiseWithError:[STPCheckoutAPIClient cancellationError]];
        }
        STPPromise<STPCheckoutAccount*> *accountPromise = [STPPromise<STPCheckoutAccount *> new];
        NSURL *url = [[NSURL URLWithString:CheckoutBaseURLString] URLByAppendingPathComponent:@"account"];
        NSString *internationalizedPhone = [STPCardValidator sanitizedNumericStringForString:phone];
        if (![internationalizedPhone hasPrefix:@"1"]) {
            internationalizedPhone = [@"1" stringByAppendingString:internationalizedPhone];
        }
        if (![internationalizedPhone hasPrefix:@"+"]) {
            internationalizedPhone = [@"+" stringByAppendingString:internationalizedPhone];
        }
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        
        NSDictionary *formPayload = @{
                                      @"token": token.tokenId,
                                      @"key": weakself.publishableKey,
                                      @"phone": internationalizedPhone,
                                      @"email": email,
                                      @"merchant_name": self.merchantName,
                                      };
        [request stp_setFormPayload:formPayload];
        [[weakself.accountSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            STPCheckoutAccount *account = [STPCheckoutAccount accountWithData:data URLResponse:response];
            if (account) {
                [accountPromise succeed:account];
            } else {
                [accountPromise fail:error ?: [strongself.class genericRememberMeErrorWithResponseData:data message:@"Failed to parse account response"]];
            }
        }] resume];
        return accountPromise;
    }];
}

- (nullable STPToken *)parseTokenFromResponse:(NSURLResponse *)response
                                         data:(NSData *)data {
    if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
        return nil;
    }
    if (((NSHTTPURLResponse *)response).statusCode != 200) {
        return nil;
    }
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [STPToken decodedObjectFromAPIResponse:json[@"token"]];
}

+ (NSError *)cancellationError {
    return [NSError errorWithDomain:StripeDomain code:STPCancellationError userInfo:@{
      NSLocalizedDescriptionKey: NSLocalizedString(@"The operation was cancelled", nil)
                                                                                    }];
}

+ (NSError *)genericRememberMeErrorWithResponseData:(NSData *)responseData
                                            message:(NSString *)message {
    NSInteger code = STPAPIError;
    NSDictionary *json;
    id object = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil];
    if ([object isKindOfClass:[NSDictionary class]]) {
        json = object;
        if ([json[@"reason"] isEqualToString:@"too_many_attempts"]) {
            code = STPCheckoutTooManyAttemptsError;
        }
    }
    
    return [NSError errorWithDomain:StripeDomain code:code userInfo:@{
    NSLocalizedDescriptionKey: [NSLocalizedString(@"Something went wrong with remember me: ", nil) stringByAppendingString:message]
    }];
}

@end
