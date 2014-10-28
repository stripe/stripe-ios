//
//  Stripe.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "STPAPIConnection.h"
#import "Stripe.h"
#import "STPUtils.h"

NSString *const kStripeiOSVersion = @"2.2.1";

@implementation Stripe

static NSString *defaultKey;
static NSString *const apiURLBase = @"api.stripe.com";
static NSString *const apiVersion = @"v1";
static NSString *const tokenEndpoint = @"tokens";

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'Stripe' is a static class and cannot be instantiated."];
    return nil;
}

#pragma mark Private Helpers

+ (NSURL *)apiURL {
    NSURL *url = [[[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]] URLByAppendingPathComponent:apiVersion]
        URLByAppendingPathComponent:tokenEndpoint];
    return url;
}

+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completion:(STPCompletionBlock)handler {
    if (requestError) {
        // If this is an error that Stripe returned, let's handle it as a StripeDomain error
        NSDictionary *jsonDictionary = nil;
        if (body && (jsonDictionary = [self dictionaryFromJSONData:body error:nil]) && [jsonDictionary valueForKey:@"error"] != nil) {
            handler(nil, [self errorFromStripeResponse:jsonDictionary]);
        } else {
            handler(nil, requestError);
        }
    } else {
        NSError *parseError;
        NSDictionary *jsonDictionary = [self dictionaryFromJSONData:body error:&parseError];

        if (jsonDictionary == nil) {
            handler(nil, parseError);
        } else if ([(NSHTTPURLResponse *)response statusCode] == 200) {
            handler([[STPToken alloc] initWithAttributeDictionary:jsonDictionary], nil);
        } else {
            handler(nil, [self errorFromStripeResponse:jsonDictionary]);
        }
    }
}

+ (NSDictionary *)dictionaryFromJSONData:(NSData *)data error:(NSError **)outError {
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

    if (jsonDictionary == nil) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: STPUnexpectedError,
            STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
        };

        if (outError) {
            *outError = [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
        }

        return nil;
    }

    return jsonDictionary;
}

+ (void)validateKey:(NSString *)publishableKey {
    if (!publishableKey || [publishableKey isEqualToString:@""]) {
        [NSException raise:@"InvalidPublishableKey"
                    format:@"You must use a valid publishable key to create a token. For more info, see https://stripe.com/docs/stripe.js"];
    }

    if ([publishableKey hasPrefix:@"sk_"]) {
        [NSException
             raise:@"InvalidPublishableKey"
            format:@"You are using a secret key to create a token, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js"];
    }
}

+ (NSDictionary *)cardErrorCodeMap {
    static id errorDictionary = nil;

    if (!errorDictionary) {
        errorDictionary = @{
            @"incorrect_number": @{@"code": STPIncorrectNumber, @"message": STPCardErrorInvalidNumberUserMessage},
            @"invalid_number": @{@"code": STPInvalidNumber, @"message": STPCardErrorInvalidNumberUserMessage},
            @"invalid_expiry_month": @{@"code": STPInvalidExpMonth, @"message": STPCardErrorInvalidExpMonthUserMessage},
            @"invalid_expiry_year": @{@"code": STPInvalidExpYear, @"message": STPCardErrorInvalidExpYearUserMessage},
            @"invalid_cvc": @{@"code": STPInvalidCVC, @"message": STPCardErrorInvalidCVCUserMessage},
            @"expired_card": @{@"code": STPExpiredCard, @"message": STPCardErrorExpiredCardUserMessage},
            @"incorrect_cvc": @{@"code": STPIncorrectCVC, @"message": STPCardErrorInvalidCVCUserMessage},
            @"card_declined": @{@"code": STPCardDeclined, @"message": STPCardErrorDeclinedUserMessage},
            @"processing_error": @{@"code": STPProcessingError, @"message": STPCardErrorProcessingErrorUserMessage},
        };
    }

    return errorDictionary;
}

+ (NSError *)errorFromStripeResponse:(NSDictionary *)jsonDictionary {
    NSDictionary *errorDictionary = jsonDictionary[@"error"];
    NSString *type = errorDictionary[@"type"];
    NSString *devMessage = errorDictionary[@"message"];
    NSString *parameter = errorDictionary[@"param"];
    NSInteger code = 0;

    // There should always be a message and type for the error
    if (devMessage == nil || type == nil) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: STPUnexpectedError,
            STPErrorMessageKey: @"Could not interpret the error response that was returned from Stripe."
        };
        return [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[STPErrorMessageKey] = devMessage;

    if (parameter) {
        userInfo[STPErrorParameterKey] = [STPUtils stringByReplacingSnakeCaseWithCamelCase:parameter];
    }

    if ([type isEqualToString:@"api_error"]) {
        code = STPAPIError;
        userInfo[NSLocalizedDescriptionKey] = STPUnexpectedError;
    } else if ([type isEqualToString:@"invalid_request_error"]) {
        code = STPInvalidRequestError;
        userInfo[NSLocalizedDescriptionKey] = devMessage;
    } else if ([type isEqualToString:@"card_error"]) {
        code = STPCardError;

        NSDictionary *codeMapEntry = [Stripe cardErrorCodeMap][errorDictionary[@"code"]];

        if (codeMapEntry) {
            userInfo[STPCardErrorCodeKey] = codeMapEntry[@"code"];
            userInfo[NSLocalizedDescriptionKey] = codeMapEntry[@"message"];
        } else {
            userInfo[STPCardErrorCodeKey] = errorDictionary[@"code"];
            userInfo[NSLocalizedDescriptionKey] = devMessage;
        }
    }

    return [[NSError alloc] initWithDomain:StripeDomain code:code userInfo:userInfo];
}

#pragma mark Public Interface
+ (NSString *)defaultPublishableKey {
    return defaultKey;
}

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    [self validateKey:publishableKey];
    defaultKey = publishableKey;
}

+ (void)createTokenWithCard:(STPCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(STPCompletionBlock)handler {
    if (card == nil) {
        [NSException raise:@"RequiredParameter" format:@"'card' is required to create a token"];
    }

    if (handler == nil) {
        [NSException raise:@"RequiredParameter" format:@"'handler' is required to use the token that is created"];
    }

    [self validateKey:publishableKey];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.apiURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [card formEncode];
    [request setValue:[self JSONStringForObject:[self stripeUserAgentDetails]] forHTTPHeaderField:@"X-Stripe-User-Agent"];
    [request setValue:[@"Bearer " stringByAppendingString:publishableKey] forHTTPHeaderField:@"Authorization"];

    [[[STPAPIConnection alloc] initWithRequest:request] runOnOperationQueue:queue
                                                                 completion:^(NSURLResponse *response, NSData *body, NSError *requestError) {
                                                                     [self handleTokenResponse:response body:body error:requestError completion:handler];
                                                                 }];
}

+ (void)requestTokenWithID:(NSString *)tokenId
            publishableKey:(NSString *)publishableKey
            operationQueue:(NSOperationQueue *)queue
                completion:(STPCompletionBlock)handler {
    if (tokenId == nil) {
        [NSException raise:@"RequiredParameter" format:@"'tokenId' is required to retrieve a token"];
    }

    if (handler == nil) {
        [NSException raise:@"RequiredParameter" format:@"'handler' is required to use the token that is requested"];
    }

    [self validateKey:publishableKey];

    NSURL *url = [self.apiURL URLByAppendingPathComponent:tokenId];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    [request setValue:[self JSONStringForObject:[self stripeUserAgentDetails]] forHTTPHeaderField:@"X-Stripe-User-Agent"];
    [request setValue:[@"Bearer " stringByAppendingString:publishableKey] forHTTPHeaderField:@"Authorization"];

    [[[STPAPIConnection alloc] initWithRequest:request] runOnOperationQueue:queue
                                                                 completion:^(NSURLResponse *response, NSData *body, NSError *requestError) {
                                                                     [self handleTokenResponse:response body:body error:requestError completion:handler];
                                                                 }];
}

#pragma mark Shorthand methods -

+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler {
    [self requestTokenWithID:tokenId publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler {
    [self requestTokenWithID:tokenId publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId completion:(STPCompletionBlock)handler {
    [self requestTokenWithID:tokenId publishableKey:[self defaultPublishableKey] operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

#pragma mark Utility methods -

+ (NSDictionary *)stripeUserAgentDetails {
    NSMutableDictionary *details = [@{
        @"lang": @"objective-c",
        @"bindings_version": kStripeiOSVersion,
    } mutableCopy];
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        details[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    if (deviceType) {
        details[@"type"] = deviceType;
    }
    NSString *model = [UIDevice currentDevice].localizedModel;
    if (model) {
        details[@"model"] = model;
    }
    NSString *vendorIdentifier = [[UIDevice currentDevice].identifierForVendor UUIDString];
    if (vendorIdentifier) {
        details[@"vendor_identifier"] = vendorIdentifier;
    }
    return [details copy];
}

+ (NSString *)JSONStringForObject:(id)object {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil] encoding:NSUTF8StringEncoding];
}

@end
