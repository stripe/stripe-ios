//
//  STPCountryPickerDataSource.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCountryPickerDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"

@implementation STPCountryPickerDataSource

+ (NSArray<NSString *>*)sepaCountryCodes {
    return @[
             @"AT",
             @"BE",
             @"BG",
             @"CH",
             @"CY",
             @"CZ",
             @"DE",
             @"DK",
             @"EE",
             @"ES",
             @"FI",
             @"FR",
             @"GB",
             @"GR",
             @"HR",
             @"HU",
             @"IE",
             @"IS",
             @"IT",
             @"LI",
             @"LV",
             @"LT",
             @"LU",
             @"MC",
             @"MT",
             @"NL",
             @"NO",
             @"PL",
             @"PT",
             @"RO",
             @"SE",
             @"SK",
             @"SI",
             @"SM",
             ];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInitWithCountryCodes:[NSLocale ISOCountryCodes]];
    }
    return self;
}

- (instancetype)initWithCountryCodes:(NSArray<NSString *>*)countryCodes {
    self = [super init];
    if (self) {
        [self commonInitWithCountryCodes:countryCodes];
    }
    return self;
}

- (void)commonInitWithCountryCodes:(NSArray<NSString *>*)countryCodes {
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSMutableArray *otherCountryCodes = [countryCodes mutableCopy];
    [otherCountryCodes sortUsingComparator:^NSComparisonResult(NSString *code1, NSString *code2) {
        NSString *localeID1 = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: code1}];
        NSString *localeID2 = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: code2}];
        NSString *name1 = [locale displayNameForKey:NSLocaleIdentifier value:localeID1];
        NSString *name2 = [locale displayNameForKey:NSLocaleIdentifier value:localeID2];
        return [name1 compare:name2];
    }];
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    if (countryCodes && [otherCountryCodes containsObject:countryCode]) {
        [otherCountryCodes removeObject:countryCode];
        self.countryCodes = [@[@"", countryCode] arrayByAddingObjectsFromArray:otherCountryCodes];
    }
    else {
        self.countryCodes = [@[@""] arrayByAddingObjectsFromArray:otherCountryCodes];
    }
}

- (NSInteger)numberOfRowsInPicker {
    return [self.countryCodes count];
}

- (NSInteger)indexOfPickerValue:(NSString *)value {
    return [self.countryCodes indexOfObject:value];
}

- (NSString *)pickerValueForRow:(NSInteger)row {
    NSString *countryCode = [self.countryCodes stp_boundSafeObjectAtIndex:row];
    return countryCode ?: @"";
}

- (NSString *)pickerTitleForRow:(NSInteger)row {
    NSString *displayName;
    NSString *countryCode = [self.countryCodes stp_boundSafeObjectAtIndex:row];
    if (countryCode) {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: countryCode}];
        displayName = [[NSLocale autoupdatingCurrentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
    }
    return displayName ?: @"";
}

@end
