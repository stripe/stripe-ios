//
//  STPGiropaySourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPGiropaySourceInfoDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodType.h"
#import "STPTextFieldTableViewCell.h"

@implementation STPGiropaySourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                prefilledInformation:(STPUserInformation *)prefilledInfo {
    self = [super initWithSourceParams:sourceParams prefilledInformation:prefilledInfo];
    if (self) {
        self.paymentMethodType = [STPPaymentMethodType giropay];
        STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
        nameCell.placeholder = STPLocalizedString(@"Account Holder Name", @"Caption for Name field on bank info form");
        nameCell.contents = prefilledInfo.billingAddress.name;
        self.cells = @[nameCell];
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    STPSourceParams *params = [self.sourceParams copy];
    NSMutableDictionary *owner = [NSMutableDictionary new];
    if (params.owner) {
        owner = [params.owner mutableCopy];
    }
    STPTextFieldTableViewCell *nameCell = [self.cells stp_boundSafeObjectAtIndex:0];
    owner[@"name"] = nameCell.contents;
    params.owner = owner;

    NSString *name = params.owner[@"name"];
    if (name.length > 0) {
        return params;
    }
    return nil;
}

@end
