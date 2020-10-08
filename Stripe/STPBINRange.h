//
//  STPBINRange.h
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPCardBrand.h"

NS_ASSUME_NONNULL_BEGIN

@class STPBINRange;
typedef void (^STPRetrieveBINRangesCompletionBlock)(NSArray<STPBINRange *> * _Nullable, NSError * _Nullable);

@interface STPBINRange : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSUInteger length;
@property (nonatomic, readonly) STPCardBrand brand;
@property (nonatomic, readonly, copy) NSString *qRangeLow;
@property (nonatomic, readonly, copy) NSString *qRangeHigh;
@property (nonatomic, nullable, readonly) NSString *country;
@property (nonatomic, readonly) BOOL isCardMetadata; // indicates bin range was downloaded from edge service

+ (BOOL)isLoadingCardMetadataForPrefix:(NSString *)binPrefix;


+ (NSArray<STPBINRange *> *)allRanges;
+ (NSArray<STPBINRange *> *)binRangesForNumber:(NSString *)number;
+ (NSArray<STPBINRange *> *)binRangesForBrand:(STPCardBrand)brand;
+ (instancetype)mostSpecificBINRangeForNumber:(NSString *)number;

+ (NSUInteger)maxCardNumberLength;
+ (NSUInteger)minLengthForFullBINRange;

+ (BOOL)hasBINRangesForPrefix:(NSString *)binPrefix;
+ (BOOL)isInvalidBINPrefix:(NSString *)binPrefix;

// This will asynchronously check if we have already fetched metadata for this prefix and if we have not will
// issue a network request to retrieve it if possible.
+ (void)retrieveBINRangesForPrefix:(NSString *)binPrefix completion:(STPRetrieveBINRangesCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
