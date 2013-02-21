//
//  Stripe.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import "Stripe.h"
#import "StripeError.h"
#import "STPCard.h"
#import "STPToken.h"

@interface Stripe()
+ (NSString *)URLEncodedString:(NSString *)string;
+ (NSString *)camelCaseFromUnderscoredString:(NSString *)string;
+ (NSDictionary *)requestPropertiesFromCard:(STPCard *)card;
+ (NSData *)formEncodedDataFromCard:(STPCard *)card;
+ (void)validateKey:(NSString *)publishableKey;
+ (NSError *)errorFromStripeResponse:(NSDictionary *)jsonDictionary;
+ (NSDictionary *)camelCasedResponseFromStripeResponse:(NSDictionary *)jsonDictionary;
+ (NSDictionary *)dictionaryFromJSONData:(NSData *)data error:(NSError **)outError;
+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completion:(STPCompletionBlock)handler;
+ (NSURL *)apiURLWithPublishableKey:(NSString *)publishableKey;
@end

@implementation Stripe
static NSString *defaultKey;
static NSString * const apiURLBase = @"api.stripe.com";
static NSString * const apiVersion = @"v1";
static NSString * const tokenEndpoint = @"tokens";

+ (id)alloc
{
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'Stripe' is a static class and cannot be instantiated."];
    return nil;
}

#pragma mark Private Helpers
+ (NSURL *)apiURLWithPublishableKey:(NSString *)publishableKey
{
    NSURL *url = [[[NSURL URLWithString:
              [NSString stringWithFormat:@"https://%@:@%@", [self URLEncodedString:publishableKey], apiURLBase]]
             URLByAppendingPathComponent:apiVersion]
            URLByAppendingPathComponent:tokenEndpoint];
    return url;
}

+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completion:(STPCompletionBlock)handler
{
    if (requestError)
    {
        // If this is an error that Stripe returned, let's handle it as a StripeDomain error
        NSDictionary *jsonDictionary = NULL;
        if (body && (jsonDictionary = [self dictionaryFromJSONData:body error:NULL]) && [jsonDictionary valueForKey:@"error"] != NULL)
        {
            handler(nil, [self errorFromStripeResponse:jsonDictionary]);
        }
        // Otherwise, return the raw NSURLError error
        else
            handler(nil, requestError);
    }
    else
    {
        NSError *parseError;
        NSDictionary *jsonDictionary = [self dictionaryFromJSONData:body error:&parseError];

        if (jsonDictionary == NULL)
            handler(nil, parseError);
        else if ([(NSHTTPURLResponse *)response statusCode] == 200)
            handler([[STPToken alloc] initWithAttributeDictionary:[self camelCasedResponseFromStripeResponse:jsonDictionary]], nil);
        else
            handler(nil, [self errorFromStripeResponse:jsonDictionary]);
    }
}

+ (NSDictionary *)dictionaryFromJSONData:(NSData *)data error:(NSError **)outError
{
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

    if (jsonDictionary == NULL)
    {
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : STPUnexpectedError,
        STPErrorMessageKey : [NSString stringWithFormat:@"The response from Stripe failed to get parsed into valid JSON."]
        };

        if (outError) {
            *outError = [[NSError alloc] initWithDomain:StripeDomain
                                                   code:STPAPIError
                                               userInfo:userInfoDict];
        }
        return NULL;
    }
    return jsonDictionary;
}

+ (NSDictionary *)camelCasedResponseFromStripeResponse:(NSDictionary *)jsonDictionary
{
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in jsonDictionary)
    {
        if ([key isEqualToString:@"card"])
            [attributeDictionary setObject:[self camelCasedResponseFromStripeResponse:[jsonDictionary valueForKey:key]] forKey:key];
        else
            [attributeDictionary setObject:[jsonDictionary valueForKey:key] forKey:[self camelCaseFromUnderscoredString:key]];
    }
    return attributeDictionary;
}

+ (NSString *)camelCaseFromUnderscoredString:(NSString *)string
{
    if (string == NULL || [string isEqualToString:@""])
        return @"";

    NSMutableString *output = [NSMutableString string];
    BOOL makeNextCharacterUpperCase = NO;
    for (NSInteger index = 0; index < [string length]; index += 1)
    {
        NSString *character = [string substringWithRange:NSMakeRange(index, 1)];
        if ([character isEqualToString:@"_"] && index != [string length] - 1)
            makeNextCharacterUpperCase = YES;
        else if (makeNextCharacterUpperCase == YES)
        {
            [output appendString:[character uppercaseString]];
            makeNextCharacterUpperCase = NO;
        }
        else
            [output appendString:character];
    }
    return output;
}

+ (void)validateKey:(NSString *)publishableKey
{
    if (!publishableKey || [publishableKey isEqualToString:@""])
        [NSException raise:@"InvalidPublishableKey" format:@"You must use a valid publishable key to create a token.  For more info, see https://stripe.com/docs/stripe.js"];

    if ([publishableKey hasPrefix:@"sk_"])
        [NSException raise:@"InvalidPublishableKey" format:@"You are using a secret key to create a token, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js"];
}

/* This code is adapted from the code by David DeLong in this StackOverflow post:
    http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string .  It is protected under the terms of a Creative Commons
    license: http://creativecommons.org/licenses/by-sa/3.0/
 */
+ (NSString *)URLEncodedString:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    int sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i)
    {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ')
            [output appendString:@"+"];
        else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                       (thisChar >= 'a' && thisChar <= 'z') ||
                       (thisChar >= 'A' && thisChar <= 'Z') ||
                       (thisChar >= '0' && thisChar <= '9'))
                [output appendFormat:@"%c", thisChar];
        else
            [output appendFormat:@"%%%02X", thisChar];
    }
    return output;
}

+ (NSDictionary *)requestPropertiesFromCard:(STPCard *)card
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            card.number         ? card.number : [NSNull null],                                      @"number",
            card.expMonth       ? [NSString stringWithFormat:@"%u", card.expMonth] : [NSNull null], @"exp_month",
            card.expYear        ? [NSString stringWithFormat:@"%u", card.expYear] : [NSNull null],  @"exp_year",
            card.cvc            ? card.cvc : [NSNull null],                                         @"cvc",
            card.name           ? card.name : [NSNull null],                                        @"name",
            card.addressLine1   ? card.addressLine1 : [NSNull null],                                @"address_line1",
            card.addressLine2   ? card.addressLine2 : [NSNull null],                                @"address_line2",
            card.addressCity    ? card.addressCity : [NSNull null],                                 @"address_city",
            card.addressState   ? card.addressState : [NSNull null],                                @"address_state",
            card.addressZip     ? card.addressZip : [NSNull null],                                  @"address_zip",
            card.addressCountry ? card.addressCountry : [NSNull null],                              @"address_country",
            nil];
}

+ (NSData *)formEncodedDataFromCard:(STPCard *)card
{
    NSMutableString *body = [NSMutableString string];
    NSDictionary *attributes = [self requestPropertiesFromCard:card];

    for (NSString *key in attributes) {
        NSString *value = [attributes objectForKey:key];
        if ((id)value == [NSNull null]) continue;

        if (body.length != 0)
            [body appendString:@"&"];

        if ([value isKindOfClass:[NSString class]])
            value = [self URLEncodedString:value];

        [body appendFormat:@"card[%@]=%@", [self URLEncodedString:key], value];
    }

    return [body dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSError *)errorFromStripeResponse:(NSDictionary *)jsonDictionary
{
    NSDictionary *errorDictionary = [jsonDictionary valueForKey:@"error"];
    NSString *type = [errorDictionary valueForKey:@"type"];
    NSString *devMessage = [errorDictionary valueForKey:@"message"];
    NSString *parameter = [errorDictionary valueForKey:@"param"];
    NSString *userMessage = NULL;
    NSString *cardErrorCode = NULL;
    NSInteger code = 0;

    // There should always be a message and type for the error
    if (devMessage == NULL || type == NULL)
    {
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : STPUnexpectedError,
                                               STPErrorMessageKey : [NSString stringWithFormat:@"Could not interpret the error response that was returned from Stripe."]
        };
        return [[NSError alloc] initWithDomain:StripeDomain
                                          code:STPAPIError
                                      userInfo:userInfoDict];
    }

    NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
    [userInfoDict setValue:devMessage forKey:STPErrorMessageKey];

    if (parameter)
    {
        parameter = [self camelCaseFromUnderscoredString:parameter];
        [userInfoDict setValue:parameter forKey:STPErrorParameterKey];
    }

    if ([type isEqualToString:@"api_error"])
    {
        userMessage = STPUnexpectedError;
        code = STPAPIError;
    }
    else if ([type isEqualToString:@"invalid_request_error"])
    {
        code = STPInvalidRequestError;
        // This is probably not correct, but I think it's correct enough in most cases.
        userMessage = devMessage;
    }
    else if ([type isEqualToString:@"card_error"])
    {
        code = STPCardError;
        cardErrorCode = [jsonDictionary valueForKey:@"code"];
        if ([cardErrorCode isEqualToString:@"incorrect_number"])
        {
            cardErrorCode = STPIncorrectNumber;
            userMessage = STPCardErrorInvalidNumberUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"invalid_number"])
        {
            cardErrorCode = STPInvalidNumber;
            userMessage = STPCardErrorInvalidNumberUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"invalid_expiry_month"])
        {
            cardErrorCode = STPInvalidExpMonth;
            userMessage = STPCardErrorInvalidExpMonthUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"invalid_expiry_year"])
        {
            cardErrorCode = STPInvalidExpYear;
            userMessage = STPCardErrorInvalidExpYearUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"invalid_cvc"])
        {
            cardErrorCode = STPInvalidCVC;
            userMessage = STPCardErrorInvalidCVCUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"expired_card"])
        {
            cardErrorCode = STPExpiredCard;
            userMessage = STPCardErrorExpiredCardUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"incorrect_cvc"])
        {
            cardErrorCode = STPIncorrectCVC;
            userMessage = STPCardErrorInvalidCVCUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"card_declined"])
        {
            cardErrorCode = STPCardDeclined;
            userMessage = STPCardErrorDeclinedUserMessage;
        }
        else if ([cardErrorCode isEqualToString:@"processing_error"])
        {
            cardErrorCode = STPProcessingError;
            userMessage = STPCardErrorProcessingErrorUserMessage;
        }
        else
            userMessage = devMessage;

        [userInfoDict setValue:cardErrorCode forKey:STPCardErrorCodeKey];
    }

    [userInfoDict setValue:userMessage forKey:NSLocalizedDescriptionKey];

    return [[NSError alloc] initWithDomain:StripeDomain
                                      code:code
                                  userInfo:userInfoDict];
}

#pragma mark Public Interface
+ (NSString*)defaultPublishableKey { return defaultKey; }

+ (void)setDefaultPublishableKey:(NSString *)publishableKey
{
    [self validateKey:publishableKey];
    defaultKey = publishableKey;
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler
{
    if (card == NULL)
        [NSException raise:@"RequiredParameter" format:@"'card' is required to create a token"];

    if (handler == NULL)
        [NSException raise:@"RequiredParameter" format:@"'handler' is required to use the token that is created"];

    [self validateKey:publishableKey];

    NSURL *url = [self apiURLWithPublishableKey:publishableKey];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    request.HTTPBody = [self formEncodedDataFromCard:card];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *requestError)
     {
         [self handleTokenResponse:response body:body error:requestError completion:handler];
     }];
}

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler
{
    if (tokenId == NULL)
        [NSException raise:@"RequiredParameter" format:@"'tokenId' is required to retrieve a token"];

    if (handler == NULL)
        [NSException raise:@"RequiredParameter" format:@"'handler' is required to use the token that is requested"];

    [self validateKey:publishableKey];

    NSURL *url = [[self apiURLWithPublishableKey:publishableKey] URLByAppendingPathComponent:tokenId];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *requestError)
     {
         [self handleTokenResponse:response body:body error:requestError completion:handler];
     }];

}

+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler
{
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler
{
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler
{
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler
{
    [self requestTokenWithID:tokenId publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler
{
    [self requestTokenWithID:tokenId publishableKey:[self defaultPublishableKey] operationQueue:queue completion:handler];
}

+ (void)requestTokenWithID:(NSString *)tokenId completion:(STPCompletionBlock)handler
{
    [self requestTokenWithID:tokenId publishableKey:[self defaultPublishableKey] operationQueue:[NSOperationQueue mainQueue] completion:handler];
}
@end
