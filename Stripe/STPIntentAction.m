//
//  STPIntentNextAction.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPIntentAction+Private.h"

#import "STPIntentActionRedirectToURL.h"
#import "STPIntentActionUseStripeSDK.h"
#import "STPIntentActionOXXODisplayDetails.h"
#import "STPIntentActionAlipayHandleRedirect.h"

#import "NSDictionary+Stripe.h"

@interface STPIntentAction()

@property (nonatomic) STPIntentActionType type;
@property (nonatomic, strong, nullable) STPIntentActionRedirectToURL *redirectToURL;
@property (nonatomic, strong, nullable) STPIntentActionUseStripeSDK *useStripeSDK;
@property (nonatomic, strong, nullable) STPIntentActionOXXODisplayDetails *oxxoDisplayDetails;
@property (nonatomic, nullable) STPIntentActionAlipayHandleRedirect *alipayHandleRedirect;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPIntentAction

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                               
                               // Type
                               [NSString stringWithFormat:@"type = %@", [[self class] stringFromActionType:self.type]],
                               ] mutableCopy];
    
    // omit properties that don't apply to this type
    switch (self.type) {
        case STPIntentActionTypeRedirectToURL:
            [props addObject:[NSString stringWithFormat:@"redirectToURL = %@", self.redirectToURL]];
            break;
        case STPIntentActionTypeUseStripeSDK:
            [props addObject:[NSString stringWithFormat:@"useStripeSDK = %@", self.useStripeSDK]];
            break;
        case STPIntentActionTypeOXXODisplayDetails:
            [props addObject:[NSString stringWithFormat:@"oxxoDisplayDetails = %@", self.oxxoDisplayDetails]];
        case STPIntentActionTypeAlipayHandleRedirect:
            [props addObject:[NSString stringWithFormat:@"alipayHandleRedirect = %@", self.alipayHandleRedirect]];
            break;
        case STPIntentActionTypeUnknown:
            // unrecognized type, just show the original dictionary for debugging help
            [props addObject:[NSString stringWithFormat:@"allResponseFields = %@", self.allResponseFields]];
    }
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (STPIntentActionType)actionTypeFromString:(NSString *)string {
    NSDictionary<NSString *, NSNumber *> *map = @{
                                                  @"redirect_to_url": @(STPIntentActionTypeRedirectToURL),
                                                  @"use_stripe_sdk": @(STPIntentActionTypeUseStripeSDK),
                                                  @"oxxo_display_details": @(STPIntentActionTypeOXXODisplayDetails),
                                                  @"alipay_handle_redirect": @(STPIntentActionTypeAlipayHandleRedirect),
                                                  };
    
    NSString *key = string.lowercaseString;
    NSNumber *statusNumber = map[key] ?: @(STPIntentActionTypeUnknown);
    return statusNumber.integerValue;
}

+ (NSString *)stringFromActionType:(STPIntentActionType)actionType {
    switch (actionType) {
        case STPIntentActionTypeRedirectToURL:
            return @"redirect_to_url";
        case STPIntentActionTypeUseStripeSDK:
            return @"use_stripe_sdk";
        case STPIntentActionTypeOXXODisplayDetails:
            return @"oxxo_display_details";
        case STPIntentActionTypeAlipayHandleRedirect:
            return @"alipay_handle_redirection";
        case STPIntentActionTypeUnknown:
            break;
    }
    
    // catch any unknown values here
    return @"unknown";
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    NSString *rawType = [dict stp_stringForKey:@"type"];
    if (!dict || !rawType) {
        return nil;
    }
    
    STPIntentActionType type = [self actionTypeFromString:rawType];
    NSDictionary *redirectDict = [dict stp_dictionaryForKey:@"redirect_to_url"];
    STPIntentActionRedirectToURL *redirect = [STPIntentActionRedirectToURL decodedObjectFromAPIResponse:redirectDict];
    
    NSDictionary *useStripeSDKDict = [dict stp_dictionaryForKey:@"use_stripe_sdk"];
    STPIntentActionUseStripeSDK *useStripeSDK = [STPIntentActionUseStripeSDK decodedObjectFromAPIResponse:useStripeSDKDict];

    NSDictionary *oxxoDisplayDetailsDict = [dict stp_dictionaryForKey:@"oxxo_display_details"];
    STPIntentActionOXXODisplayDetails *oxxoDisplayDetails = [STPIntentActionOXXODisplayDetails decodedObjectFromAPIResponse:oxxoDisplayDetailsDict];
    
    NSDictionary *alipayHandleRedirectDict = [dict stp_dictionaryForKey:@"alipay_handle_redirect"];
    STPIntentActionAlipayHandleRedirect *alipayHandleRedirect = [STPIntentActionAlipayHandleRedirect decodedObjectFromAPIResponse:alipayHandleRedirectDict];
    
    STPIntentAction *action = [self new];
    
    // Only set the type to a recognized value if we *also* have the expected sub-details.
    // ex: If the server said it was `.redirectToURL`, but decoding the
    // STPIntentActionRedirectToURL object fails, map type to `.unknown`
    if (type == STPIntentActionTypeRedirectToURL && redirect != nil) {
        action.type = type;
        action.redirectToURL = redirect;
    } else if (type == STPIntentActionTypeUseStripeSDK && useStripeSDK != nil) {
        action.type = type;
        action.useStripeSDK = useStripeSDK;
    } else if (type == STPIntentActionTypeOXXODisplayDetails && oxxoDisplayDetails != nil) {
        action.type = type;
        action.oxxoDisplayDetails = oxxoDisplayDetails;
    } else if (type == STPIntentActionTypeAlipayHandleRedirect && alipayHandleRedirect != nil) {
        action.type = type;
        action.alipayHandleRedirect = alipayHandleRedirect;
    } else {
        action.type = STPIntentActionTypeUnknown;
    }
    
    action.allResponseFields = dict;
    
    return action;
}

#pragma mark - Deprecated

- (STPIntentActionRedirectToURL *)authorizeWithURL {
    return self.redirectToURL;
}

@end
