//
//  STPIDEALSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPIDEALSourceInfoDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPIDEALBankSelectorDataSource.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethodType.h"
#import "STPTextFieldTableViewCell.h"

@implementation STPIDEALSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                prefilledInformation:(STPUserInformation *)prefilledInfo {
    self = [super initWithSourceParams:sourceParams prefilledInformation:prefilledInfo];
    if (self) {
        self.paymentMethodType = [STPPaymentMethodType ideal];
        STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
        nameCell.placeholder = STPLocalizedString(@"Account Holder Name", @"Caption for Name field on bank info form");
        nameCell.contents = prefilledInfo.billingAddress.name;
        self.cells = @[nameCell];
        self.selectorDataSource = [STPIDEALBankSelectorDataSource new];
        [self.selectorDataSource selectRowWithValue:prefilledInfo.idealBank];
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    STPSourceParams *params = [self.sourceParams copy];
    NSMutableDictionary *owner = [NSMutableDictionary new];
    if (params.owner) {
        owner = [params.owner mutableCopy];
    }
    NSMutableDictionary *additionalParams = [NSMutableDictionary new];
    if (params.additionalAPIParameters) {
        additionalParams = [params.additionalAPIParameters mutableCopy];
    }
    STPTextFieldTableViewCell *nameCell = [self.cells stp_boundSafeObjectAtIndex:0];
    owner[@"name"] = nameCell.contents;
    params.owner = owner;
    NSMutableDictionary *idealDict = [NSMutableDictionary new];
    if (additionalParams[@"ideal"]) {
        idealDict = additionalParams[@"ideal"];
    }
    NSInteger selectedRow = self.selectorDataSource.selectedRow;
    NSString *selectedBank = [self.selectorDataSource selectorValueForRow:selectedRow];
    if (selectedBank) {
        idealDict[@"bank"] = selectedBank;
        additionalParams[@"ideal"] = idealDict;
        params.additionalAPIParameters = additionalParams;
    }
    NSString *name = params.owner[@"name"];
    NSString *bank = params.additionalAPIParameters[@"ideal"][@"bank"];
    if (name.length > 0 && bank.length > 0) {
        return params;
    }
    return nil;
}

@end
