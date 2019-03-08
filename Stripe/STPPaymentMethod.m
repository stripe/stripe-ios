//
//  STPPaymentMethod.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethod.h"

#import "NSDictionary+Stripe.h"
#import "STPPaymentMethodBillingDetails.h"
#import "STPPaymentMethodCard.h"

@interface STPPaymentMethod ()

@property (nonatomic, nullable) NSString *identifier;
@property (nonatomic, nullable) NSDate *created;
@property (nonatomic) BOOL liveMode;
@property (nonatomic, nullable) NSString *type;
@property (nonatomic, nullable) STPPaymentMethodBillingDetails *billingDetails;
@property (nonatomic, nullable) STPPaymentMethodCard *card;
@property (nonatomic, nullable) NSString *customerId;
@property (nonatomic, nullable, copy) NSDictionary<NSString*, NSString *> *metadata;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end


@implementation STPPaymentMethod

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentMethod * paymentMethod = [self new];
    paymentMethod.allResponseFields = dict;
    paymentMethod.identifier = [dict stp_stringForKey:@"id"];
    paymentMethod.created = [dict stp_dateForKey:@"created"];
    paymentMethod.liveMode = [dict stp_boolForKey:@"livemode" or:NO];
    paymentMethod.billingDetails = [STPPaymentMethodBillingDetails decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"billing_details"]];
    paymentMethod.card = [STPPaymentMethodCard decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"card"]];
    paymentMethod.type = [dict stp_stringForKey:@"type"];
    paymentMethod.customerId = [dict stp_stringForKey:@"customer"];
    paymentMethod.metadata = [dict stp_dictionaryForKey:@"metadata"];
    return paymentMethod;
}

@end
