//
//  STPSofortSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSofortSourceInfoDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPCountryPickerDataSource.h"
#import "STPLocalizationUtils.h"
#import "STPTextFieldTableViewCell.h"

@implementation STPSofortSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super initWithSourceParams:sourceParams];
    if (self) {
        self.title = STPLocalizedString(@"Giropay Info", @"Title for form to collect Giropay account info");
        self.cells = @[];
        
        // TODO: country picker
//        STPPickerTableViewCell *countryCell = [[STPPickerTableViewCell alloc] init];
//        countryCell.placeholder = STPLocalizedString(@"Country", @"Caption for Country field on bank info form");
//        NSArray *sofortCountries = @[@"AT", @"BE", @"FR", @"DE", @"NL"];
//        countryCell.pickerDataSource = [[STPCountryPickerDataSource alloc] initWithCountryCodes:sofortCountries];
//        NSDictionary *sofortDict = self.sourceParams.additionalAPIParameters[@"sofort"];
//        if (sofortDict) {
//            countryCell.contents = sofortDict[@"country"];
//        }
    }
    return self;
}

- (STPSourceParams *)completedSourceParams {
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
    return params;
}

@end
