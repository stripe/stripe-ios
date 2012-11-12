//
//  Stripe.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import "Stripe.h"

@interface Stripe()
+ (NSString *)URLEncodedString:(NSString *)string;
+ (NSString *)camelCaseFromUnderscoredString:(NSString *)string;
+ (NSDictionary *)requestPropertiesFromCard:(STPCard *)card;
+ (NSData *)formEncodedDataFromCard:(STPCard *)card;
+ (void)validateKey:(NSString *)publishableKey;
+ (NSError *)errorFromStripeResponse:(NSDictionary *)JSONDictionary;
+ (NSDictionary *)camelCasedResponseFromStripeResponse:(NSDictionary *)JSONDictionary;
+ (NSDictionary *)parseJSONBody:(NSData *)data error:(NSError **)outError;
+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completionHandler:(void (^)(STPToken*, NSError*))handler;
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
+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completionHandler:(void (^)(STPToken*, NSError*))handler
{
    // If the request failed entirely, expose the underlying request error
    if (requestError)
        handler(NULL, requestError);
    else
    {
        NSError *parseError;
        NSDictionary *JSONDictionary = [self parseJSONBody:body error:&parseError];
    
        if (JSONDictionary == NULL)
            handler(NULL, parseError);
        else if ([(NSHTTPURLResponse *)response statusCode] == 200)
            handler([[STPToken alloc] initWithAttributeDictionary:[self camelCasedResponseFromStripeResponse:JSONDictionary]], NULL);
        else
            handler(NULL, [self errorFromStripeResponse:[JSONDictionary valueForKey:@"error"]]);
    }
}

+ (NSDictionary *)parseJSONBody:(NSData *)data error:(NSError **)outError
{
    NSDictionary *JSONDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    
    if (JSONDictionary == NULL)
    {
        NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : STPUnexpectedError,
        STPErrorMessageKey : [NSString stringWithFormat:@"The response from Stripe failed to get parsed into valid JSON."]
        };
        
        *outError = [[NSError alloc] initWithDomain:StripeDomain
                                             code:STPAPIError
                                          userInfo:userInfoDict];
        return NULL;
    }
    return JSONDictionary;
}

+ (NSDictionary *)camelCasedResponseFromStripeResponse:(NSDictionary *)JSONDictionary
{
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    for (NSString *key in JSONDictionary)
    {
        if ([key isEqualToString:@"card"])
            [attributeDictionary setObject:[self camelCasedResponseFromStripeResponse:[JSONDictionary valueForKey:key]] forKey:key];
        else
            [attributeDictionary setObject:[JSONDictionary valueForKey:key] forKey:[self camelCaseFromUnderscoredString:key]];
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
        if ([character isEqualToString:@"_"])
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
    if (!publishableKey || publishableKey == @"")
        [NSException raise:@"InvalidPublishableKey" format:@"You must use a valid publishable key to create a token.  For more info, see https://stripe.com/docs/stripe.js"];

    if ([publishableKey substringWithRange:NSMakeRange(0, 3)] == @"sk_")
        [NSException raise:@"InvalidPublishableKey" format:@"You are using a secret key to create a token, instead of the publishable one. For more info, see https://stripe.com/docs/stripe.js"];
}

+ (NSString *)URLEncodedString:(NSString *)string {
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (__bridge CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8);
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

+ (NSError *)errorFromStripeResponse:(NSDictionary *)JSONDictionary
{
    NSString *type = [JSONDictionary valueForKey:@"type"];
    NSString *devMessage = [JSONDictionary valueForKey:@"message"];
    NSString *parameter = [JSONDictionary valueForKey:@"param"];
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
        cardErrorCode = [JSONDictionary valueForKey:@"code"];
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

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken *, NSError *))handler
{
    if (card == NULL)
        [NSException raise:@"RequiredParameter" format:@"'card' is required to create a token"];

    [self validateKey:publishableKey];

    NSURL *url = [[[NSURL URLWithString:
                    [NSString stringWithFormat:@"https://%@:@%@", [self URLEncodedString:publishableKey], apiURLBase]]
                   URLByAppendingPathComponent:apiVersion]
                  URLByAppendingPathComponent:tokenEndpoint];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";

    request.HTTPBody =[self formEncodedDataFromCard:card];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *requestError)
     {
         [self handleTokenResponse:response body:body error:requestError completionHandler:handler];
     }];
}

+ (void)getTokenWithId:(NSString *)tokenId publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler
{
    if (tokenId == NULL)
        [NSException raise:@"RequiredParameter" format:@"'tokenId' is required to retrieve a token"];
    
    [self validateKey:publishableKey];
    
    NSURL *url = [[[[NSURL URLWithString:
                    [NSString stringWithFormat:@"https://%@:@%@", [self URLEncodedString:publishableKey], apiURLBase]]
                   URLByAppendingPathComponent:apiVersion]
                  URLByAppendingPathComponent:tokenEndpoint] URLByAppendingPathComponent:tokenId];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *body, NSError *requestError)
     {
         [self handleTokenResponse:response body:body error:requestError completionHandler:handler];
     }];

}

+ (void)createTokenWithCard:(STPCard *)card completionHandler:(void (^)(STPToken *, NSError *))handler
{
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] completionHandler:handler];
}

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completionHandler:(void (^)(STPToken*, NSError*))handler
{
    [self createTokenWithCard:card publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completionHandler:handler];
}

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler
{
    [self createTokenWithCard:card publishableKey:[self defaultPublishableKey] operationQueue:queue completionHandler:handler];
}

+ (void)getTokenWithId:(NSString *)tokenId publishableKey:(NSString *)publishableKey completionHandler:(void (^)(STPToken*, NSError*))handler
{
    [self getTokenWithId:tokenId publishableKey:publishableKey operationQueue:[NSOperationQueue mainQueue] completionHandler:handler];
}

+ (void)getTokenWithId:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler
{
    [self getTokenWithId:tokenId publishableKey:[self defaultPublishableKey] operationQueue:queue completionHandler:handler];
}

+ (void)getTokenWithId:(NSString *)tokenId completionHandler:(void (^)(STPToken*, NSError*))handler
{
    [self getTokenWithId:tokenId publishableKey:[self defaultPublishableKey] operationQueue:[NSOperationQueue mainQueue] completionHandler:handler];
}
@end
