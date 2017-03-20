//
//  STPCountryPickerDataSource.m
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCountryPickerDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPLocalizationUtils.h"

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
    [STPLocalizationUtils sortCountryCodesByDisplayName:otherCountryCodes];
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
    if (!value) {
        return NSNotFound;
    }
    return [self.countryCodes indexOfObject:value];
}

- (NSString *)pickerValueForRow:(NSInteger)row {
    return [self.countryCodes stp_boundSafeObjectAtIndex:row];
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
