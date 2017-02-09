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

@implementation STPGiropaySourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super initWithSourceParams:sourceParams];
    if (self) {
        self.title = STPLocalizedString(@"Giropay Info", @"Title for form to collect Giropay account info");
        STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
        nameCell.placeholder = STPLocalizedString(@"Name", @"Caption for Name field on bank info form");
        if (self.sourceParams.owner) {
            nameCell.contents = self.sourceParams.owner[@"name"];
        }
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
