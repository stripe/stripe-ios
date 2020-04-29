//
//  STPPaymentIntentShippingDetails.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 4/27/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPPaymentIntentShippingDetails.h"

#import "STPPaymentIntentShippingDetailsAddress.h"
#import "NSDictionary+Stripe.h"

@interface STPPaymentIntentShippingDetails ()
@property (nonatomic, copy, nonnull, readwrite) NSDictionary *allResponseFields;

@property (nonatomic, nullable) STPPaymentIntentShippingDetailsAddress *address;
@property (nonatomic, nullable, copy) NSString *name;
@property (nonatomic, nullable, copy) NSString *carrier;
@property (nonatomic, nullable, copy) NSString *phone;
@property (nonatomic, nullable, copy) NSString *trackingNumber;
@end

@implementation STPPaymentIntentShippingDetails

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       [NSString stringWithFormat:@"address = %@", self.address],
                       [NSString stringWithFormat:@"name = %@", self.name],
                       [NSString stringWithFormat:@"carrier = %@", self.carrier],
                       [NSString stringWithFormat:@"phone = %@", self.phone],
                       [NSString stringWithFormat:@"trackingNumber = %@", self.trackingNumber],
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    STPPaymentIntentShippingDetails *shipping = [self new];
    shipping.allResponseFields = dict;
    shipping.address = [STPPaymentIntentShippingDetailsAddress decodedObjectFromAPIResponse:[dict stp_dictionaryForKey:@"address"]];
    shipping.name = [dict stp_stringForKey:@"name"];
    shipping.carrier = [dict stp_stringForKey:@"carrier"];
    shipping.phone = [dict stp_stringForKey:@"phone"];
    shipping.trackingNumber = [dict stp_stringForKey:@"tracking_number"];
    return shipping;
}

@end
