//
//  STPPaymentMethodListDeserializer.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/16/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodListDeserializer.h"

#import "STPPaymentMethod.h"
#import "NSDictionary+Stripe.h"

@interface STPPaymentMethodListDeserializer()

@property (nonatomic, copy) NSArray<STPPaymentMethod *> *paymentMethods;
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@end

@implementation STPPaymentMethodListDeserializer

#pragma mark STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    // Required fields
    NSArray<NSDictionary *> *data = [dict stp_arrayForKey:@"data"];
    if (!data) {
        return nil;
    }
    
    STPPaymentMethodListDeserializer *paymentMethodsDeserializer = [[self class] new];
    NSMutableArray<STPPaymentMethod *> *paymentMethods = [NSMutableArray new];
    for (NSDictionary *paymentMethodJSON in data) {
        STPPaymentMethod *paymentMethod = [STPPaymentMethod decodedObjectFromAPIResponse:paymentMethodJSON];
        if (paymentMethod) {
            [paymentMethods addObject:paymentMethod];
        }
    }
    paymentMethodsDeserializer.paymentMethods = paymentMethods;
    return paymentMethodsDeserializer;
}



@end
