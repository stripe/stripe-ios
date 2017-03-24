//
//  STPBankPickerDataSource.m
//  Stripe
//
//  Created by Ben Guo on 2/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPIDEALBankSelectorDataSource.h"

#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "NSArray+Stripe_BoundSafe.h"

@interface STPIDEALBankSelectorDataSource()

/// Dictionary mapping bank names to bank codes
@property (nonatomic) NSDictionary<NSString *,NSString *>*bankNameToBankCode;

/// Sorted array of bank names
@property (nonatomic) NSArray<NSString *>*bankNames;

@property (nonatomic, assign) NSInteger selectedRow;

@end

@implementation STPIDEALBankSelectorDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        _bankNameToBankCode = @{
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
        _bankNames = [[_bankNameToBankCode allKeys] sortedArrayUsingSelector:@selector(compare:)];
        _selectedRow = NSNotFound;
    }
    return self;
}

- (NSString *)selectorTitle {
    return STPLocalizedString(@"Bank", @"Title for bank picker section");
}

- (NSInteger)numberOfRowsInSelector {
    return [self.bankNames count];
}

- (BOOL)selectRowWithValue:(NSString *)value {
    if (!value) {
        self.selectedRow = NSNotFound;
    } else {
        NSString *name = [[self.bankNameToBankCode allKeysForObject:value] firstObject];
        if (name) {
            self.selectedRow = [self.bankNames indexOfObject:name];
        } else {
            self.selectedRow = NSNotFound;
        }
    }
    return self.selectedRow != NSNotFound;
}

- (NSString *)selectorValueForRow:(NSInteger)row {
    NSString *name = [self.bankNames stp_boundSafeObjectAtIndex:row];
    if (name) {
        return self.bankNameToBankCode[name];
    }
    return nil;
}

- (NSString *)selectorTitleForRow:(NSInteger)row {
    return [self.bankNames stp_boundSafeObjectAtIndex:row];
}

- (UIImage *)selectorImageForRow:(__unused NSInteger)row {
    return [STPImageLibrary addIcon];
}

@end
