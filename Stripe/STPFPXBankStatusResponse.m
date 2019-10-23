//
//  STPFPXBankStatusResponse.m
//  Stripe
//
//  Created by David Estes on 10/21/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPFPXBankStatusResponse.h"
#import "NSDictionary+Stripe.h"

@interface STPFPXBankStatusResponse ()

@property (nonatomic, readonly) NSDictionary<NSString *, NSNumber *> *bankList;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPFPXBankStatusResponse

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }
    
    STPFPXBankStatusResponse *statusResponse = [self new];
    statusResponse->_bankList = [dict stp_dictionaryForKey:@"parsed_bank_status"];
    statusResponse->_allResponseFields = dict;

    return statusResponse;
}

- (BOOL)bankBrandIsOnline:(STPFPXBankBrand)bankBrand {
    NSString *bankCode = STPBankCodeFromFPXBankBrand(bankBrand, NO);
    NSNumber *bankStatus = [self.bankList objectForKey:bankCode];
    if (bankCode != nil && bankStatus != nil) {
        return [bankStatus boolValue];
    }
    // This status endpoint isn't reliable. If we don't know this bank's status, default to online.
    // The worst that will happen here is that the user ends up at their bank's "Down For Maintenance" page when checking out.
    return YES;
}

@end
