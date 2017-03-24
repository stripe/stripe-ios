//
//  STPSofortCountrySelectorDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSofortCountrySelectorDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"

@interface STPSofortCountrySelectorDataSource()

@property (nonatomic) NSArray<NSString *>*countryCodes;

@property (nonatomic, assign) NSInteger selectedRow;

@end

@implementation STPSofortCountrySelectorDataSource

- (instancetype)init {
    self = [super init];
    if (self) {
        NSMutableArray *countryCodes = [@[@"AT", @"BE", @"FR", @"DE", @"NL"] mutableCopy];
        [STPLocalizationUtils sortCountryCodesByDisplayName:countryCodes];
        _countryCodes = countryCodes;
        _selectedRow = NSNotFound;
    }
    return self;
}

- (NSString *)selectorTitle {
    return STPLocalizedString(@"Country", @"Title for country picker section");
}

- (NSInteger)numberOfRowsInSelector {
    return [self.countryCodes count];
}

- (BOOL)selectRowWithValue:(NSString *)value {
    if (!value) {
        self.selectedRow = NSNotFound;
    } else {
        self.selectedRow = [self.countryCodes indexOfObject:value];
    }
    return self.selectedRow != NSNotFound;
}

- (NSString *)selectorValueForRow:(NSInteger)row {
    return [self.countryCodes stp_boundSafeObjectAtIndex:row];
}

- (NSString *)selectorTitleForRow:(NSInteger)row {
    NSString *displayName;
    NSString *countryCode = [self.countryCodes stp_boundSafeObjectAtIndex:row];
    if (countryCode) {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: countryCode}];
        displayName = [[NSLocale autoupdatingCurrentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
    }
    return displayName ?: @"";
}

- (UIImage *)selectorImageForRow:(__unused NSInteger)row {
    return [STPImageLibrary addIcon]; // TODO
}

@end
