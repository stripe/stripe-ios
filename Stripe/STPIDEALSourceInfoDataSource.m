//
//  STPIDEALSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPIDEALSourceInfoDataSource.h"

#import "NSArray+Stripe_BoundSafe.h"
#import "STPLocalizationUtils.h"
#import "STPPickerTableViewCell.h"
#import "STPBankPickerDataSource.h"

@implementation STPIDEALSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super initWithSourceParams:sourceParams];
    if (self) {
        self.title = STPLocalizedString(@"iDEAL Info", @"Title for form to collect iDEAL account info");
        STPTextFieldTableViewCell *nameCell = [[STPTextFieldTableViewCell alloc] init];
        nameCell.placeholder = STPLocalizedString(@"Name", @"Caption for Name field on bank info form");
        if (self.sourceParams.owner) {
            nameCell.contents = self.sourceParams.owner[@"name"];
        }
        STPPickerTableViewCell *bankCell = [[STPPickerTableViewCell alloc] init];
        bankCell.placeholder = STPLocalizedString(@"Bank", @"Caption for Bank field on bank info form");
        bankCell.pickerDataSource = [STPBankPickerDataSource iDEALBankDataSource];
        NSDictionary *idealDict = self.sourceParams.additionalAPIParameters[@"ideal"];
        if (idealDict) {
            bankCell.contents = idealDict[@"bank"];
        }
        self.cells = @[nameCell, bankCell];
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
    STPTextFieldTableViewCell *bankCell = [self.cells stp_boundSafeObjectAtIndex:1];
    idealDict[@"bank"] = bankCell.contents;
    additionalParams[@"ideal"] = idealDict;
    params.additionalAPIParameters = additionalParams;

    NSString *name = params.owner[@"name"];
    NSString *bank = params.additionalAPIParameters[@"ideal"][@"bank"];
    if (name.length > 0 && bank.length > 0) {
        return params;
    }
    return nil;
}

@end
