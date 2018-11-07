//
//  STPPaymentIntentSourceAction.m
//  Stripe
//
//  Created by Daniel Jackson on 11/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentSourceAction.h"

#import "STPPaymentIntent+Private.h"
#import "STPPaymentIntentSourceActionAuthorizeWithURL.h"

#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentSourceAction()
@property (nonatomic, readwrite) STPPaymentIntentSourceActionType type;
@property (nonatomic, strong, nullable, readwrite) STPPaymentIntentSourceActionAuthorizeWithURL* authorizeWithURL;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@end

@implementation STPPaymentIntentSourceAction

@synthesize allResponseFields;

- (NSString *)description {
    NSMutableArray *props = [@[
                               // Object
                               [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                               // Type
                               [NSString stringWithFormat:@"type = %@", [STPPaymentIntent stringFromSourceActionType:self.type]],
                               ] mutableCopy];

    // omit properties that don't apply to this type
    switch (self.type) {
        case STPPaymentIntentSourceActionTypeAuthorizeWithURL:
            [props addObject:[NSString stringWithFormat:@"authorizeWithURL = %@", self.authorizeWithURL]];
            break;
        default:
            // unrecognized type, just show the original dictionary for debugging help
            [props addObject:[NSString stringWithFormat:@"allResponseFields = %@", self.allResponseFields]];
    }

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    NSString *rawType = [dict stp_stringForKey:@"type"];
    if (!dict || !rawType) {
        return nil;
    }

    STPPaymentIntentSourceActionType type = [STPPaymentIntent sourceActionTypeFromString:rawType];
    NSDictionary *authorizeDict = [dict stp_dictionaryForKey:@"authorize_with_url"];
    STPPaymentIntentSourceActionAuthorizeWithURL *authorize = [STPPaymentIntentSourceActionAuthorizeWithURL decodedObjectFromAPIResponse:authorizeDict];

    STPPaymentIntentSourceAction *sourceAction = [self new];

    // Only set the type to a recognized value if we *also* have the expected sub-details.
    // ex: If the server said it was `.authorizeWithURL`, but decoding the
    // STPPaymentIntentSourceActionAuthorizeWithURL object fails, map type to `.unknown`
    if (type == STPPaymentIntentSourceActionTypeAuthorizeWithURL && authorize) {
        sourceAction.type = type;
        sourceAction.authorizeWithURL = authorize;
    }
    else {
        sourceAction.type = STPPaymentIntentSourceActionTypeUnknown;
    }

    sourceAction.allResponseFields = dict;

    return sourceAction;
}

@end
