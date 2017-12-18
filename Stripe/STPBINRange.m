//
//  STPBINRange.m
//  Stripe
//
//  Created by Jack Flintermann on 5/24/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPBINRange.h"
#import "NSString+Stripe.h"

@interface STPBINRange()

@property (nonatomic) NSUInteger length;
@property (nonatomic) NSString *qRangeLow;
@property (nonatomic) NSString *qRangeHigh;
@property (nonatomic) STPCardBrand brand;

- (BOOL)matchesNumber:(NSString *)number;

@end


@implementation STPBINRange

+ (NSArray<STPBINRange *> *)allRanges {
    
    static NSArray<STPBINRange *> *STPBINRangeAllRanges;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *ranges = @[
                            // Catch-all values
                            @[@"", @"", @16, @(STPCardBrandUnknown)],
                            @[@"34", @"34", @15, @(STPCardBrandAmex)],
                            @[@"37", @"37", @15, @(STPCardBrandAmex)],
                            @[@"30", @"30", @14, @(STPCardBrandDinersClub)],
                            @[@"36", @"36", @14, @(STPCardBrandDinersClub)],
                            @[@"38", @"39", @14, @(STPCardBrandDinersClub)],
                            @[@"60", @"60", @16, @(STPCardBrandDiscover)],
                            @[@"62", @"62", @16, @(STPCardBrandDiscover)],
                            @[@"64", @"65", @16, @(STPCardBrandDiscover)],
                            @[@"35", @"35", @16, @(STPCardBrandJCB)],
                            @[@"50", @"59", @16, @(STPCardBrandMasterCard)],
                            @[@"22", @"27", @16, @(STPCardBrandMasterCard)],
                            @[@"67", @"67", @16, @(STPCardBrandMasterCard)], // Maestro
                            @[@"40", @"49", @16, @(STPCardBrandVisa)],
                            // Specific known BIN ranges
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
    });
    return STPBINRangeAllRanges;
}


/**
 Number matching strategy: Truncate the longer of the two numbers (theirs and our
 bounds) to match the length of the shorter one, then do numerical compare.
 */
- (BOOL)matchesNumber:(NSString *)number {

    BOOL withinLowRange = NO;
    BOOL withinHighRange = NO;

    if (number.length < self.qRangeLow.length) {
        withinLowRange = number.integerValue >= [self.qRangeLow substringToIndex:number.length].integerValue;
    }
    else {
        withinLowRange = [number substringToIndex:self.qRangeLow.length].integerValue >= self.qRangeLow.integerValue;
    }

    if (number.length < self.qRangeHigh.length) {
        withinHighRange = number.integerValue <= [self.qRangeHigh substringToIndex:number.length].integerValue;
    }
    else {
        withinHighRange = [number substringToIndex:self.qRangeHigh.length].integerValue <= self.qRangeHigh.integerValue;
    }

    return withinLowRange && withinHighRange;
}

- (NSComparisonResult)compare:(STPBINRange *)other {
    return [@(self.qRangeLow.length) compare:@(other.qRangeLow.length)];
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

@end
