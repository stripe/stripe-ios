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
#import "STPAnalyticsClient.h"
#import "STPAPIClient+Private.h"
#import "STPCard+Private.h"
#import "STPCardBINMetadata.h"
#import "STPPaymentConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

static const NSUInteger kMaxCardNumberLength = 19;
static const NSUInteger kPrefixLengthForMetadataRequest = 6;

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
    binRange->_isCardMetadata = YES;
    
    return binRange;
}

#pragma mark - Class Utilities

+ (BOOL)isLoadingCardMetadataForPrefix:(NSString *)binPrefix {
    __block BOOL isLoading = NO;
    dispatch_sync([self _retrievalQueue], ^{
        NSString *binPrefixKey = [binPrefix stp_safeSubstringToIndex:kPrefixLengthForMetadataRequest];
        isLoading = binPrefixKey != nil && sPendingRequests[binPrefixKey] != nil;
    });
    return isLoading;
}

+ (NSUInteger)maxCardNumberLength {
    return kMaxCardNumberLength;
}

+ (NSUInteger)minLengthForFullBINRange {
    return kPrefixLengthForMetadataRequest;
}

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
                                @[@"", @"", @19, @(STPCardBrandUnknown)],

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
                                @[@"81", @"81", @16, @(STPCardBrandUnionPay)],

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

// sPendingRequests contains the completion blocks for a given metadata request that we have not yet gotten a response for
static NSMutableDictionary<NSString *, NSArray<STPRetrieveBINRangesCompletionBlock> *> *sPendingRequests = nil;
// sRetrievedRanges tracks the bin prefixes for which we've already received metadata responses
static NSMutableDictionary<NSString *, NSArray<STPBINRange *> *> *sRetrievedRanges = nil;

// _retrievalQueue protects access to the two above dictionaries, sSpendingRequests and sRetrievedRanges
+ (dispatch_queue_t)_retrievalQueue {
    static dispatch_queue_t sRetrievalQueue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sRetrievalQueue = dispatch_queue_create("com.stripe.retrieveBINRangesForPrefix", DISPATCH_QUEUE_SERIAL);
        sPendingRequests = [NSMutableDictionary new];
        sRetrievedRanges = [NSMutableDictionary new];
    });
    
    return sRetrievalQueue;
}

+ (BOOL)hasBINRangesForPrefix:(NSString *)binPrefix {
    if ([self isInvalidBINPrefix:binPrefix]) {
        return YES; // we won't fetch any more info for this prefix
    }
    if (![self isVariableLengthBINPrefix:binPrefix]) {
        return YES; // if we know a card has a static length, we don't need to ask the BIN service
    }
    __block BOOL hasBINRanges = NO;
    dispatch_sync([self _retrievalQueue], ^{
        NSString *binPrefixKey = [binPrefix stp_safeSubstringToIndex:kPrefixLengthForMetadataRequest];
        hasBINRanges = binPrefixKey.length == kPrefixLengthForMetadataRequest && sRetrievedRanges[binPrefixKey] != nil;
    });
    return hasBINRanges;
}

+ (BOOL)isInvalidBINPrefix:(NSString *)binPrefix {
    NSString *firstFive = [binPrefix stp_safeSubstringToIndex:kPrefixLengthForMetadataRequest - 1];
    return ((STPBINRange *)[self mostSpecificBINRangeForNumber:firstFive]).brand == STPCardBrandUnknown;
}

+ (BOOL)isVariableLengthBINPrefix:(NSString *)binPrefix {
    NSString *firstFive = [binPrefix stp_safeSubstringToIndex:kPrefixLengthForMetadataRequest - 1];
    // Only UnionPay has variable-length cards at the moment.
    return ((STPBINRange *)[self mostSpecificBINRangeForNumber:firstFive]).brand == STPCardBrandUnionPay;
}

+ (void)retrieveBINRangesForPrefix:(NSString *)binPrefix completion:(STPRetrieveBINRangesCompletionBlock)completion {
    
    dispatch_async([self _retrievalQueue], ^{
        NSString *binPrefixKey = [binPrefix stp_safeSubstringToIndex:kPrefixLengthForMetadataRequest];
        if (sRetrievedRanges[binPrefixKey] != nil || binPrefixKey.length < kPrefixLengthForMetadataRequest || [self isInvalidBINPrefix:binPrefixKey]) {
            // if we already have a metadata response or the binPrefix isn't long enough to make a request,
            // or we know that this is not a valid BIN prefix
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
                dispatch_async([self _retrievalQueue], ^{
                    NSArray<STPBINRange *> *ranges = cardMetadata.ranges;
                    NSArray<STPRetrieveBINRangesCompletionBlock> *completionBlocks = sPendingRequests[binPrefixKey];
                    
                    [sPendingRequests removeObjectForKey:binPrefixKey];
                    if (ranges != nil) {
                        sRetrievedRanges[binPrefixKey] = ranges;
                        [self _performSyncWithAllRangesLock:^{
                            STPBINRangeAllRanges = [STPBINRangeAllRanges arrayByAddingObjectsFromArray:ranges];
                        }];
                    } else {
                        [[STPAnalyticsClient sharedClient] logCardMetadataResponseFailureWithConfiguration:[STPPaymentConfiguration sharedConfiguration]];
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
