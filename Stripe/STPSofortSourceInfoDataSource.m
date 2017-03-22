//
//  STPSofortSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSofortSourceInfoDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPLocalizationUtils.h"
#import "STPPickerTableViewCell.h"
#import "STPCountryPickerDataSource.h"

@implementation STPSofortSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super initWithSourceParams:sourceParams];
    if (self) {
        self.title = STPLocalizedString(@"Sofort Info", @"Title for form to collect Sofort account info");
        STPPickerTableViewCell *countryCell = [[STPPickerTableViewCell alloc] init];
        countryCell.placeholder = STPLocalizedString(@"Country", @"Caption for Country field on bank info form");
        NSArray *sofortCountries = @[@"AT", @"BE", @"FR", @"DE", @"NL"];
        countryCell.pickerDataSource = [[STPCountryPickerDataSource alloc] initWithCountryCodes:sofortCountries];
        NSDictionary *sofortDict = self.sourceParams.additionalAPIParameters[@"sofort"];
        if (sofortDict) {
            countryCell.contents = sofortDict[@"country"];
        }
        self.cells = @[countryCell];
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    STPSourceParams *params = [self.sourceParams copy];
    NSMutableDictionary *additionalParams = [NSMutableDictionary new];
    if (params.additionalAPIParameters) {
        additionalParams = [params.additionalAPIParameters mutableCopy];
    }
    NSMutableDictionary *sofortDict = [NSMutableDictionary new];
    if (additionalParams[@"sofort"]) {
        sofortDict = additionalParams[@"sofort"];
    }
    STPTextFieldTableViewCell *countryCell = [self.cells stp_boundSafeObjectAtIndex:0];
    sofortDict[@"country"] = countryCell.contents;
    additionalParams[@"sofort"] = sofortDict;
    params.additionalAPIParameters = additionalParams;

    NSString *country = params.additionalAPIParameters[@"sofort"][@"country"];
    if (country.length > 0) {
        return params;
    }
    return nil;
}

@end
