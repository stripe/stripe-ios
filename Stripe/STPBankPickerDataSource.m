//
//  STPBankPickerDataSource.m
//  Stripe
//
//  Created by Ben Guo on 2/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPBankPickerDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"

@interface STPBankPickerDataSource()

/// Dictionary mapping bank names to bank codes
@property (nonatomic) NSDictionary<NSString *,NSString *>*bankNameToBankCode;

/// Sorted array of bank names
@property (nonatomic) NSArray<NSString *>*bankNames;

@end

@implementation STPBankPickerDataSource

+ (STPBankPickerDataSource *)iDEALBankDataSource {
    STPBankPickerDataSource *dataSource = [[self class] new];
    dataSource.bankNameToBankCode = @{
                                      @"ABN AMRO": @"abn_amro",
                                      @"ASN Bank": @"asn_bank",
                                      @"Bunq": @"bunq",
                                      @"ING": @"ing",
                                      @"Knab": @"knab",
                                      @"Rabobank": @"rabobank",
                                      @"RegioBank": @"regiobank",
                                      @"SNS Bank": @"sns_bank",
                                      @"Triodos Bank": @"triodos_bank",
                                      @"Van Lanschot": @"van_lanschot",
                                      };
    dataSource.bankNames = [[dataSource.bankNameToBankCode allKeys] sortedArrayUsingSelector:@selector(compare:)];
    return dataSource;
}

- (NSInteger)numberOfRows {
    return [self.bankNames count];
}

- (NSInteger)indexOfValue:(NSString *)value {
    NSString *name = [[self.bankNameToBankCode allKeysForObject:value] firstObject];
    if (!name) {
        return NSNotFound;
    }
    return [self.bankNames indexOfObject:name];
}

- (NSString *)valueForRow:(NSInteger)row {
    NSString *value;
    NSString *name = [self.bankNames stp_boundSafeObjectAtIndex:row];
    if (name) {
        value = self.bankNameToBankCode[name];
    }
    return value ?: @"";
}

- (NSString *)titleForRow:(NSInteger)row {
    NSString *title = [self.bankNames stp_boundSafeObjectAtIndex:row];
    return title ?: @"";
}

@end
