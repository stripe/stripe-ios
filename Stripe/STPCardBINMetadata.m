//
//  STPCardBINMetadata.m
//  Stripe
//
//  Created by Cameron Sabol on 7/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPCardBINMetadata.h"

#import "NSDictionary+Stripe.h"
#import "STPBINRange.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPCardBINMetadata

@synthesize allResponseFields = _allResponseFields;

#pragma mark - STPAPIDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (dict == nil) {
        return nil;
    }
    
    NSMutableArray<STPBINRange *> *ranges = [NSMutableArray new];
    for (NSDictionary *rangeDict in [dict stp_arrayForKey:@"data"]) {
        if ([rangeDict isKindOfClass:[NSDictionary class]]) {
            STPBINRange *binRange = [STPBINRange decodedObjectFromAPIResponse:rangeDict];
            if (binRange != nil) {
                [ranges addObject:binRange];
            }
        }
    }
    
    STPCardBINMetadata *cardMetadata = [self new];
    cardMetadata->_allResponseFields = [dict copy];
    cardMetadata->_ranges = [ranges copy];
    
    return cardMetadata;
}

@end

NS_ASSUME_NONNULL_END
