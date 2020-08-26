//
//  STPBINRange.m
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBINRange.h"

#import "NSDictionary+Stripe.h"
#import "NSString+Stripe.h"
#import "STPAPIClient+Private.h"
#import "STPCard+Private.h"
#import "STPCardBINMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPBINRange()

@property (nonatomic) NSUInteger length;
@property (nonatomic, copy) NSString *qRangeLow;
@property (nonatomic, copy) NSString *qRangeHigh;
@property (nonatomic, nullable, copy) NSString *country;
@property (nonatomic) STPCardBrand brand;

- (BOOL)matchesNumber:(NSString *)number;

@end


@implementation STPBINRange

@synthesize allResponseFields = _allResponseFields;



/**
 Number matching strategy: Truncate the longer of the two numbers (theirs and our
 bounds) to match the length of the shorter one, then do numerical compare.
 */
- (BOOL)matchesNumber:(NSString *)number {

    BOOL withinLowRange = NO;
    BOOL withinHighRange = NO;

    if (number.length < self.qRangeLow.length) {
        withinLowRange = number.integerValue >= [self.qRangeLow substringToIndex:number.length].integerValue;
    } else {
        withinLowRange = [number substringToIndex:self.qRangeLow.length].integerValue >= self.qRangeLow.integerValue;
    }

    if (number.length < self.qRangeHigh.length) {
        withinHighRange = number.integerValue <= [self.qRangeHigh substringToIndex:number.length].integerValue;
    } else {
        withinHighRange = [number substringToIndex:self.qRangeHigh.length].integerValue <= self.qRangeHigh.integerValue;
    }

    return withinLowRange && withinHighRange;
}

- (NSComparisonResult)compare:(STPBINRange *)other {
    return [@(self.qRangeLow.length) compare:@(other.qRangeLow.length)];
}

#pragma mark - STPAPIResponseDecodable

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    STPBINRange *binRange = [self new];
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (dict == nil || binRange == nil) {
        return nil;
    }
    
    NSString *qRangeLow = [dict stp_stringForKey:@"account_range_low"];
    NSString *qRangeHigh = [dict stp_stringForKey:@"account_range_high"];
    NSString *brandString = [dict stp_stringForKey:@"brand"];
    NSNumber *length = [dict stp_numberForKey:@"pan_length"];
    if (qRangeLow == nil ||
        qRangeHigh == nil ||
        brandString == nil ||
        length == nil ||
        [STPCard brandFromString:brandString] == STPCardBrandUnknown
        ) {
        return nil;
    }
    
    binRange.qRangeLow = qRangeLow;
    binRange.qRangeHigh = qRangeHigh;
    binRange.brand = [STPCard brandFromString:brandString];
    binRange.length = [length unsignedIntegerValue];
    binRange.country = [dict stp_stringForKey:@"country"];
    
    return binRange;
}

#pragma mark - Class Utilities

static NSArray<STPBINRange *> *STPBINRangeAllRanges = nil;

+ (void)_performSyncWithAllRangesLock:(dispatch_block_t)block {
    static dispatch_queue_t sAllRangesLockQueue = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sAllRangesLockQueue = dispatch_queue_create("com.stripe.STPBINRange.allRanges", DISPATCH_QUEUE_SERIAL);
    });

    dispatch_sync(sAllRangesLockQueue, ^{
        if (STPBINRangeAllRanges == nil) {
            NSArray *ranges = @[
                                // Unknown
                                @[@"", @"", @16, @(STPCardBrandUnknown)],

                                // American Express
                                @[@"34", @"34", @15, @(STPCardBrandAmex)],
                                @[@"37", @"37", @15, @(STPCardBrandAmex)],

                                // Diners Club
                                @[@"30", @"30", @16, @(STPCardBrandDinersClub)],
                                @[@"36", @"36", @14, @(STPCardBrandDinersClub)],
                                @[@"38", @"39", @16, @(STPCardBrandDinersClub)],

                                // Discover
                                @[@"60", @"60", @16, @(STPCardBrandDiscover)],
                                @[@"64", @"65", @16, @(STPCardBrandDiscover)],

                                // JCB
                                @[@"35", @"35", @16, @(STPCardBrandJCB)],

                                // Mastercard
                                @[@"50", @"59", @16, @(STPCardBrandMasterCard)],
                                @[@"22", @"27", @16, @(STPCardBrandMasterCard)],
                                @[@"67", @"67", @16, @(STPCardBrandMasterCard)], // Maestro

                                // UnionPay
                                @[@"62", @"62", @16, @(STPCardBrandUnionPay)],

                                // Visa
                                @[@"40", @"49", @16, @(STPCardBrandVisa)],
                                @[@"413600", @"413600", @13, @(STPCardBrandVisa)],
                                @[@"444509", @"444509", @13, @(STPCardBrandVisa)],
                                @[@"444509", @"444509", @13, @(STPCardBrandVisa)],
                                @[@"444550", @"444550", @13, @(STPCardBrandVisa)],
                                @[@"450603", @"450603", @13, @(STPCardBrandVisa)],
                                @[@"450617", @"450617", @13, @(STPCardBrandVisa)],
                                @[@"450628", @"450629", @13, @(STPCardBrandVisa)],
                                @[@"450636", @"450636", @13, @(STPCardBrandVisa)],
                                @[@"450640", @"450641", @13, @(STPCardBrandVisa)],
                                @[@"450662", @"450662", @13, @(STPCardBrandVisa)],
                                @[@"463100", @"463100", @13, @(STPCardBrandVisa)],
                                @[@"476142", @"476142", @13, @(STPCardBrandVisa)],
                                @[@"476143", @"476143", @13, @(STPCardBrandVisa)],
                                @[@"492901", @"492902", @13, @(STPCardBrandVisa)],
                                @[@"492920", @"492920", @13, @(STPCardBrandVisa)],
                                @[@"492923", @"492923", @13, @(STPCardBrandVisa)],
                                @[@"492928", @"492930", @13, @(STPCardBrandVisa)],
                                @[@"492937", @"492937", @13, @(STPCardBrandVisa)],
                                @[@"492939", @"492939", @13, @(STPCardBrandVisa)],
                                @[@"492960", @"492960", @13, @(STPCardBrandVisa)],
                                ];
            NSMutableArray *binRanges = [NSMutableArray array];
            for (NSArray *range in ranges) {
                STPBINRange *binRange = [self.class new];
                binRange.qRangeLow  = range[0];
                binRange.qRangeHigh = range[1];
                binRange.length     = [range[2] unsignedIntegerValue];
                binRange.brand = [range[3] integerValue];
                [binRanges addObject:binRange];
            }
            STPBINRangeAllRanges = [binRanges copy];
        }
        block();
    });
}

+ (NSArray<STPBINRange *> *)allRanges {
    __block NSArray<STPBINRange *> *ret = nil;
    [self _performSyncWithAllRangesLock:^{
        ret = [STPBINRangeAllRanges copy];
    }];
    
    return ret;
}


+ (NSArray<STPBINRange *> *)binRangesForNumber:(NSString *)number {
    return [[self allRanges] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(STPBINRange *range, __unused NSDictionary *bindings) {
        return [range matchesNumber:number];
    }]];
}

+ (instancetype)mostSpecificBINRangeForNumber:(NSString *)number {
    NSArray *validRanges = [[self allRanges] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(STPBINRange *range, __unused NSDictionary *bindings) {
        return [range matchesNumber:number];
    }]];
    return [[validRanges sortedArrayUsingSelector:@selector(compare:)] lastObject];
}

+ (NSArray<STPBINRange *> *)binRangesForBrand:(STPCardBrand)brand {
    return [[self allRanges] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(STPBINRange *range, __unused NSDictionary *bindings) {
        return range.brand == brand;
    }]];
}

+ (void)retrieveBINRangesForPrefix:(NSString *)binPrefix completion:(STPRetrieveBINRangesCompletionBlock)completion {
    // sPendingRequests contains the completion blocks for a given metadata request that we have not yet gotten a response for
    static NSMutableDictionary<NSString *, NSArray<STPRetrieveBINRangesCompletionBlock> *> *sPendingRequests = nil;
    // sRetrievedRanges tracks the bin prefixes for which we've already received metadata responses
    static NSMutableDictionary<NSString *, NSArray<STPBINRange *> *> *sRetrievedRanges = nil;
    // sRetrievalQueue protects access to the two above dictionaries, sSpendingRequests and sRetrievedRanges
    static dispatch_queue_t sRetrievalQueue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sRetrievalQueue = dispatch_queue_create("com.stripe.retrieveBINRangesForPrefix", DISPATCH_QUEUE_SERIAL);
        sPendingRequests = [NSMutableDictionary new];
        sRetrievedRanges = [NSMutableDictionary new];
    });
    
    dispatch_async(sRetrievalQueue, ^{
        NSString *binPrefixKey = [binPrefix stp_safeSubstringToIndex:6];
        if (sRetrievedRanges[binPrefixKey] != nil || binPrefixKey.length < 6) {
            // if we already have a metadata response or the binPrefix isn't long enough to make a request,
            // return the bin ranges we already have on device
            dispatch_async(dispatch_get_main_queue(), ^{
                completion([self binRangesForNumber:binPrefix], nil);
            });
        } else if (sPendingRequests[binPrefixKey] != nil) {
            // A request for this prefix is already in flight, add the completion block to sPendingRequests
            sPendingRequests[binPrefixKey] = [sPendingRequests[binPrefixKey] arrayByAddingObject:[completion copy]];
        } else {
            
            sPendingRequests[binPrefixKey] = @[[completion copy]];
            [[STPAPIClient sharedClient] retrieveCardBINMetadataForPrefix:binPrefixKey
                                                           withCompletion:^(STPCardBINMetadata * _Nullable cardMetadata, NSError * _Nullable error) {
                dispatch_async(sRetrievalQueue, ^{
                    NSArray<STPBINRange *> *ranges = cardMetadata.ranges;
                    NSArray<STPRetrieveBINRangesCompletionBlock> *completionBlocks = sPendingRequests[binPrefixKey];
                    
                    [sPendingRequests removeObjectForKey:binPrefixKey];
                    if (ranges != nil) {
                        sRetrievedRanges[binPrefixKey] = ranges;
                        [self _performSyncWithAllRangesLock:^{
                            STPBINRangeAllRanges = [STPBINRangeAllRanges arrayByAddingObjectsFromArray:ranges];
                        }];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        for (STPRetrieveBINRangesCompletionBlock block in completionBlocks) {
                            block(ranges, error);
                        }
                    });
                });
            }];
        }
    });
    
    
}

@end

NS_ASSUME_NONNULL_END
