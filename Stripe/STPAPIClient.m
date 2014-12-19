//
//  STPAPIClient.m
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPAPIClient.h"
#import "STPAPIConnection.h"
#import "STPToken.h"
#import "StripeError.h"
#import <objc/runtime.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#endif

static NSString *const apiURLBase = @"api.stripe.com";
static NSString *const apiVersion = @"v1";
static NSString *const tokenEndpoint = @"tokens";
static NSString *const kStripeiOSVersion = @"2.2.2";
static NSString *STPDefaultPublishableKey;
static char kAssociatedClientKey;

@implementation Stripe

+ (void)setDefaultPublishableKey:(NSString *)publishableKey {
    STPDefaultPublishableKey = publishableKey;
}

+ (NSString *)defaultPublishableKey {
    return STPDefaultPublishableKey;
}

@end

@interface STPAPIClient ()
@property (nonatomic, readwrite) NSURL *apiURL;
@end

@implementation STPAPIClient

+ (instancetype)sharedClient {
    static id sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ sharedClient = [[self alloc] init]; });
    return sharedClient;
}

- (instancetype)init {
    return [self initWithPublishableKey:[Stripe defaultPublishableKey]];
}

- (instancetype)initWithPublishableKey:(NSString *)publishableKey {
    self = [super init];
    if (self) {
        [self.class validateKey:publishableKey];
        _apiURL = [[[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", apiURLBase]] URLByAppendingPathComponent:apiVersion]
            URLByAppendingPathComponent:tokenEndpoint];
        _publishableKey = [publishableKey copy];
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)createTokenWithData:(NSData *)data completion:(STPCompletionBlock)completion {
    NSCAssert(data != nil, @"'data' is required to create a token");
    NSCAssert(completion != nil, @"'completion' is required to use the token that is created");

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.apiURL];
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    [request setValue:[self.class JSONStringForObject:[self.class stripeUserAgentDetails]] forHTTPHeaderField:@"X-Stripe-User-Agent"];
    [request setValue:[@"Bearer " stringByAppendingString:self.publishableKey] forHTTPHeaderField:@"Authorization"];

    STPAPIConnection *connection = [[STPAPIConnection alloc] initWithRequest:request];

    // use the runtime to ensure we're not dealloc'ed before completion
    objc_setAssociatedObject(connection, &kAssociatedClientKey, self, OBJC_ASSOCIATION_RETAIN);

    [connection runOnOperationQueue:self.operationQueue
                         completion:^(NSURLResponse *response, NSData *body, NSError *requestError) {
                             if (requestError) {
                                 // If this is an error that Stripe returned, let's handle it as a StripeDomain error
                                 if (body) {
                                     NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
                                     if ([jsonDictionary valueForKey:@"error"] != nil) {
                                         completion(nil, [self.class errorFromStripeResponse:jsonDictionary]);
                                         return;
                                     }
                                 }
                                 completion(nil, requestError);
                                 return;
                             } else {
                                 NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:body options:0 error:NULL];
                                 if (!jsonDictionary) {
                                     NSDictionary *userInfo = @{
                                         NSLocalizedDescriptionKey: STPUnexpectedError,
                                         STPErrorMessageKey: @"The response from Stripe failed to get parsed into valid JSON."
                                     };
                                     NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPAPIError userInfo:userInfo];
                                     completion(nil, error);
                                 } else if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                                     completion([[STPToken alloc] initWithAttributeDictionary:jsonDictionary], nil);
                                 } else {
                                     completion(nil, [self.class errorFromStripeResponse:jsonDictionary]);
                                 }
                             }
                             // at this point it's safe to be dealloced
                             objc_setAssociatedObject(connection, &kAssociatedClientKey, nil, OBJC_ASSOCIATION_RETAIN);
                         }];
}

#pragma mark - private helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
+ (void)validateKey:(NSString *)publishableKey {
    NSCAssert(publishableKey != nil && ![publishableKey isEqualToString:@""],
              @"You must use a valid publishable key to create a token. For more info, see https://stripe.com/docs/stripe.js");
    BOOL secretKey = [publishableKey hasPrefix:@"sk_"];
    NSCAssert(!secretKey,
              @"You are using a secret key to create a token, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js");
#ifndef DEBUG
    if ([publishableKey.lowercaseString hasPrefix:@"pk_test"]) {
        NSLog(@"⚠️ Warning! You're building your app in a non-debug configuration, but appear to be using your Stripe test key. Make sure not to submit to "
              @"the App Store with your test keys!⚠️");
    }
#endif
}
#pragma clang diagnostic pop

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
        userInfo[STPErrorParameterKey] = [self stringByReplacingSnakeCaseWithCamelCase:parameter];
    }

    if ([type isEqualToString:@"api_error"]) {
        code = STPAPIError;
        userInfo[NSLocalizedDescriptionKey] = STPUnexpectedError;
    } else if ([type isEqualToString:@"invalid_request_error"]) {
        code = STPInvalidRequestError;
        userInfo[NSLocalizedDescriptionKey] = devMessage;
    } else if ([type isEqualToString:@"card_error"]) {
        code = STPCardError;
        NSDictionary *errorCodes = @{
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
        NSDictionary *codeMapEntry = errorCodes[errorDictionary[@"code"]];

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

#pragma mark Utility methods -

+ (NSDictionary *)stripeUserAgentDetails {
    NSMutableDictionary *details = [@{
        @"lang": @"objective-c",
        @"bindings_version": kStripeiOSVersion,
    } mutableCopy];
#if TARGET_OS_IPHONE
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version) {
        details[@"os_version"] = version;
    }
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceType = @(systemInfo.machine);
    if (deviceType) {
        details[@"type"] = deviceType;
    }
    NSString *model = [UIDevice currentDevice].localizedModel;
    if (model) {
        details[@"model"] = model;
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
        NSString *vendorIdentifier = [[[UIDevice currentDevice] performSelector:@selector(identifierForVendor)] performSelector:@selector(UUIDString)];
        if (vendorIdentifier) {
            details[@"vendor_identifier"] = vendorIdentifier;
        }
    }
#endif
    return [details copy];
}

+ (NSString *)JSONStringForObject:(id)object {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:object options:0 error:NULL] encoding:NSUTF8StringEncoding];
}

@end

@implementation STPAPIClient (PrivateMethods)

/* This code is adapted from the code by David DeLong in this StackOverflow post:
 http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string .  It is protected under the terms of a Creative Commons
 license: http://creativecommons.org/licenses/by-sa/3.0/
 */
+ (NSString *)stringByURLEncoding:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    NSInteger sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') || (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    NSArray *parts = [input componentsSeparatedByString:@"_"];
    NSMutableString *camelCaseParam = [NSMutableString string];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        [camelCaseParam appendString:(idx == 0 ? part : [part capitalizedString])];
        if (idx > 0) {
            [camelCaseParam appendString:[part capitalizedString]];
        } else {
            [camelCaseParam appendString:part];
        }
    }];

    return [camelCaseParam copy];
}

@end
