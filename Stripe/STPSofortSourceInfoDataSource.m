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
#import "STPPaymentMethodType.h"
#import "STPSofortCountrySelectorDataSource.h"
#import "STPTextFieldTableViewCell.h"

@implementation STPSofortSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super initWithSourceParams:sourceParams];
    if (self) {
        self.paymentMethodType = [STPPaymentMethodType sofort];
        self.cells = @[];
        self.selectorDataSource = [STPSofortCountrySelectorDataSource new];
        NSDictionary *sofortDict = self.sourceParams.additionalAPIParameters[@"sofort"];
        if (sofortDict) {
            [self.selectorDataSource selectRowWithValue:sofortDict[@"country"]];
        }
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
    NSInteger selectedRow = self.selectorDataSource.selectedRow;
    NSString *selectedCountry = [self.selectorDataSource selectorValueForRow:selectedRow];
    if (selectedCountry) {
        sofortDict[@"country"] = selectedCountry;
        additionalParams[@"sofort"] = sofortDict;
        params.additionalAPIParameters = additionalParams;
    }

    NSString *country = params.additionalAPIParameters[@"sofort"][@"country"];
    if (country.length > 0) {
        return params;
    }
    return nil;
}

@end
