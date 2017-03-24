//
//  STPSofortSourceInfoDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "STPSourceInfoDataSource.h"

@interface STPSofortSourceInfoDataSource : STPSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                prefilledInformation:(STPUserInformation *)prefilledInfo;

@end
