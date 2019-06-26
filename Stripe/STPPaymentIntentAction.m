//
//  STPPaymentIntentAction.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/8/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentAction+Private.h"

#import "STPPaymentIntent+Private.h"
#import "STPPaymentIntentActionRedirectToURL.h"
#import "STPPaymentIntentActionUseStripeSDK.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentAction()

@property (nonatomic) STPPaymentIntentActionType type;
@property (nonatomic, strong, nullable) STPPaymentIntentActionRedirectToURL* redirectToURL;
@property (nonatomic, strong, nullable) STPPaymentIntentActionUseStripeSDK *useStripeSDK;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentIntentAction

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                               
                               // Type
                               [NSString stringWithFormat:@"type = %@", [STPPaymentIntent stringFromActionType:self.type]],
                               ] mutableCopy];
    
    // omit properties that don't apply to this type
    switch (self.type) {
        case STPPaymentIntentActionTypeRedirectToURL:
            [props addObject:[NSString stringWithFormat:@"redirectToURL = %@", self.redirectToURL]];
            break;
        default:
            // unrecognized type, just show the original dictionary for debugging help
            [props addObject:[NSString stringWithFormat:@"allResponseFields = %@", self.allResponseFields]];
    }
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    NSString *rawType = [dict stp_stringForKey:@"type"];
    if (!dict || !rawType) {
        return nil;
    }
    
    STPPaymentIntentActionType type = [STPPaymentIntent actionTypeFromString:rawType];
    NSDictionary *redirectDict = [dict stp_dictionaryForKey:@"redirect_to_url"];
    STPPaymentIntentActionRedirectToURL *redirect = [STPPaymentIntentActionRedirectToURL decodedObjectFromAPIResponse:redirectDict];

    NSDictionary *useStripeSDKDict = [dict stp_dictionaryForKey:@"use_stripe_sdk"];
    STPPaymentIntentActionUseStripeSDK *useStripeSDK = [STPPaymentIntentActionUseStripeSDK decodedObjectFromAPIResponse:useStripeSDKDict];

    STPPaymentIntentAction *action = [self new];

    // Only set the type to a recognized value if we *also* have the expected sub-details.
    // ex: If the server said it was `.redirectToURL`, but decoding the
    // STPPaymentIntentActionRedirectToURL object fails, map type to `.unknown`
    if (type == STPPaymentIntentActionTypeRedirectToURL && redirect != nil) {
        action.type = type;
        action.redirectToURL = redirect;
    } else if (type == STPPaymentIntentActionTypeUseStripeSDK && useStripeSDK != nil) {
        action.type = type;
        action.useStripeSDK = useStripeSDK;
    } else {
        action.type = STPPaymentIntentActionTypeUnknown;
    }

    action.allResponseFields = dict;
    
    return action;
}

#pragma mark - Deprecated

- (STPPaymentIntentActionRedirectToURL *)authorizeWithURL {
    return self.redirectToURL;
}

@end
