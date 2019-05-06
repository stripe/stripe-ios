//
//  STPIssuingCardPin.m
//  Stripe
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPIssuingCardPin.h"
#import "NSDictionary+Stripe.h"

@interface STPIssuingCardPin()

@property (nonatomic, nullable) NSString *pin;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *error;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPIssuingCardPin

#pragma mark - STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    NSDictionary *error = [dict stp_dictionaryForKey:@"error"];
    if (error != nil) {
        // Return object to be able to read errors
        STPIssuingCardPin *pinObject = [self new];
        pinObject.error = error;
        return pinObject;
    }
    
    // required fields
    NSString *pin = [dict stp_stringForKey:@"pin"];
    if (!pin) {
        return nil;
    }
    
    STPIssuingCardPin *pinObject = [self new];
    pinObject.allResponseFields = dict;
    pinObject.pin = pin;
    return pinObject;
}

@end
