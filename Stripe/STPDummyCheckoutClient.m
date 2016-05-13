//
//  STPDummyCheckoutClient.m
//  Stripe
//
//  Created by Jack Flintermann on 5/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPDummyCheckoutClient.h"

@implementation STPDummyCheckoutClient

- (STPPromise<STPCheckoutAccount *> *)submitSMSCode:(__unused NSString *)code
                                    forVerification:(__unused STPCheckoutAPIVerification *)verification {
    return [STPPromise promiseWithError:[NSError new]];
}

@end
